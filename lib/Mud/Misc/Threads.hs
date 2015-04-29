{-# OPTIONS_GHC -fno-warn-type-defaults #-}
{-# LANGUAGE LambdaCase, MonadComprehensions, OverloadedStrings, ViewPatterns #-}

module Mud.Misc.Threads ( getUnusedId
                        , listenWrapper ) where

import Mud.Cmds.Debug
import Mud.Cmds.Pla
import Mud.Cmds.Util.Misc
import Mud.Cmds.Util.Pla
import Mud.Data.Misc
import Mud.Data.State.ActionParams.ActionParams
import Mud.Data.State.MsgQueue
import Mud.Data.State.MudData
import Mud.Data.State.Util.Get
import Mud.Data.State.Util.Misc
import Mud.Data.State.Util.Output
import Mud.Data.State.Util.Set
import Mud.Interp.CentralDispatch
import Mud.Interp.Login
import Mud.Misc.ANSI
import Mud.Misc.Logging hiding (logExMsg, logIOEx, logNotice, logPla)
import Mud.Misc.Persist
import Mud.TheWorld.Ids
import Mud.TheWorld.TheWorld
import Mud.TopLvlDefs.Chars
import Mud.TopLvlDefs.FilePaths
import Mud.TopLvlDefs.Misc
import Mud.Util.List
import Mud.Util.Misc
import Mud.Util.Quoting
import Mud.Util.Text hiding (headTail)
import qualified Mud.Misc.Logging as L (logExMsg, logIOEx, logNotice, logPla)

import Control.Applicative ((<$>), (<*>))
import Control.Concurrent (forkIO, killThread, threadDelay)
import Control.Concurrent.Async (async, asyncThreadId, race_, wait)
import Control.Concurrent.STM (atomically)
import Control.Concurrent.STM.TMQueue (TMQueue, closeTMQueue, newTMQueueIO, tryReadTMQueue, writeTMQueue)
import Control.Concurrent.STM.TMVar (takeTMVar)
import Control.Concurrent.STM.TQueue (newTQueueIO, readTQueue, writeTQueue)
import Control.Exception (AsyncException(..), IOException, SomeException, fromException)
import Control.Exception.Lifted (catch, finally, handle, throwTo, try)
import Control.Lens (view, views)
import Control.Lens.Operators ((%~), (&), (.~), (^.))
import Control.Monad ((>=>), forM_, forever, unless, void)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (runReaderT)
import Data.Bits (zeroBits)
import Data.List ((\\))
import Data.Monoid ((<>), getSum, mempty)
import Network (HostName, PortID(..), accept, listenOn, sClose)
import Prelude hiding (pi)
import System.FilePath ((</>))
import System.IO (BufferMode(..), Handle, Newline(..), NewlineMode(..), hClose, hIsEOF, hSetBuffering, hSetEncoding, hSetNewlineMode, latin1)
import System.Random (randomIO, randomRIO) -- TODO: Use mwc-random or tf-random. QC uses tf-random.
import System.Time.Utils (renderSecs)
import qualified Data.IntMap.Lazy as IM (keys, map)
import qualified Data.Map.Lazy as M (elems, empty)
import qualified Data.Text as T
import qualified Data.Text.IO as T (hGetLine, hPutStr, hPutStrLn, putStrLn, readFile)
import qualified Network.Info as NI (getNetworkInterfaces, ipv4, name)


default (Int)


-----


logExMsg :: T.Text -> T.Text -> SomeException -> MudStack ()
logExMsg = L.logExMsg "Mud.Misc.Threads"


logIOEx :: T.Text -> IOException -> MudStack ()
logIOEx = L.logIOEx "Mud.Misc.Threads"


logNotice :: T.Text -> T.Text -> MudStack ()
logNotice = L.logNotice "Mud.Misc.Threads"


logPla :: T.Text -> Id -> T.Text -> MudStack ()
logPla = L.logPla "Mud.Misc.Threads"


-- ==================================================
-- The "listen" thread:


listenWrapper :: MudStack ()
listenWrapper =
    let bye = liftIO . T.putStrLn $ "Goodbye!\n"
    in (logNotice "listenWrapper" "server started." >> listen) `finally` (getUptime >>= saveUptime >> closeLogs >> bye)


saveUptime :: Int -> MudStack ()
saveUptime up@(T.pack . renderSecs . toInteger -> upTxt) =
    maybe (saveIt >> logIt) checkRecord =<< (fmap . fmap) getSum getRecordUptime
  where
    saveIt            = (liftIO . writeFile uptimeFile . show $ up) `catch` logIOEx "saveUptime saveIt"
    logIt             = logHelper "."
    checkRecord recUp = case up `compare` recUp of GT -> saveIt >> logRec
                                                   _  -> logIt
    logRec            = logHelper " - it's a new record!"
    logHelper         = logNotice "saveUptime" . ("CurryMUD was up for " <>) . (upTxt <>)


listen :: MudStack ()
listen = handle listenExHandler $ setThreadType Listen >> mIf initWorld proceed halt
  where
    proceed = do
        sortAllInvs
        logInterfaces
        logNotice "listen" $ "listening for incoming connections on port " <> showText port <> "."
        sock <- liftIO . listenOn . PortNumber . fromIntegral $ port
        auxAsyncs <- mapM runAsync [ worldPersister, threadTblPurger ]
        (forever . loop $ sock) `finally` cleanUp auxAsyncs sock
    runAsync f    = onEnv $ liftIO . async . runReaderT f
    logInterfaces = liftIO NI.getNetworkInterfaces >>= \ns ->
        let ifList = T.intercalate ", " [ bracketQuote . T.concat $ [ showText . NI.name $ n
                                                                    , ": "
                                                                    , showText . NI.ipv4 $ n ] | n <- ns ]
        in logNotice "listen listInterfaces" $ "server network interfaces: " <> ifList <> "."
    loop sock = do
        (h, host, localPort) <- liftIO . accept $ sock
        logNotice "listen loop" . T.concat $ [ "connected to "
                                             , showText host
                                             , " on local port "
                                             , showText localPort
                                             , "." ]
        setTalkAsync =<< onEnv (liftIO . async . runReaderT (talk h host))
    cleanUp auxAsyncs sock = do
        logNotice "listen cleanUp" "closing the socket."
        liftIO . sClose $ sock
        mapM_ (liftIO . throwWait) auxAsyncs
        onEnv $ liftIO . atomically . void . takeTMVar . view persisterTMVar
    throwWait a = throwTo (asyncThreadId a) PlsDie >> (void . wait $ a)
    halt        = liftIO . T.putStrLn $ "Oops! There was an error loading the world. Check the error log for details."


listenExHandler :: SomeException -> MudStack ()
listenExHandler e = case fromException e of
  Just UserInterrupt -> logNotice "listenExHandler" "exiting on user interrupt."
  Just ThreadKilled  -> logNotice "listenExHandler" "thread killed."
  _                  -> logExMsg  "listenExHandler" "exception caught on listen thread" e


sortAllInvs :: MudStack ()
sortAllInvs = logNotice "sortAllInvs" "sorting all inventories." >> modifyState helper
  where
    helper ms = (ms & invTbl %~ IM.map (sortInv ms), ())


-- ==================================================
-- The "world persister" thread:


worldPersister :: MudStack ()
worldPersister = handle (threadExHandler "world persister") $ do
    setThreadType WorldPersister
    logNotice "worldPersister" "world persister started."
    let loop = (liftIO . threadDelay $ worldPersisterDelay * 10 ^ 6) >> persist
    forever loop `catch` die "world persister"


die :: T.Text -> PlsDie -> MudStack ()
die threadName _ = logNotice "die" $ "the " <> threadName <> " thread is dying."


threadExHandler :: T.Text -> SomeException -> MudStack ()
threadExHandler threadName e = do
    logExMsg "threadExHandler" ("exception caught on " <> threadName <> " thread; rethrowing to listen thread") e
    throwToListenThread e


-- ==================================================
-- The "thread table purger" thread:


threadTblPurger :: MudStack ()
threadTblPurger = handle (threadExHandler "thread table purger") $ do
    setThreadType ThreadTblPurger
    logNotice "threadTblPurger" "thread table purger started."
    let loop = (liftIO . threadDelay $ threadTblPurgerDelay * 10 ^ 6) >> purgeThreadTbls
    forever loop `catch` die "thread table purger"


-- ==================================================
-- "Talk" threads:


talk :: Handle -> HostName -> MudStack ()
talk h host = helper `finally` cleanUp
  where
    helper = do
        (mq, itq)          <- liftIO $ (,) <$> newTQueueIO <*> newTMQueueIO
        (i, dblQuote -> s) <- adHoc mq host
        setThreadType . Talk $ i
        handle (plaThreadExHandler "talk" i) $ onEnv $ \md -> do
            liftIO configBuffer
            dumpTitle mq
            prompt    mq "By what name are you known?"
            bcastAdmins $ "A new player has connected: " <> s <> "."
            logNotice "talk helper" $ "new PC name for incoming player: " <> s <> "."
            liftIO . void . forkIO . runReaderT (inacTimer i mq itq) $ md
            liftIO $ race_ (runReaderT (server  h i mq itq) md)
                           (runReaderT (receive h i mq)     md)
    configBuffer = hSetBuffering h LineBuffering >> hSetNewlineMode h nlMode >> hSetEncoding h latin1
    nlMode       = NewlineMode { inputNL = CRLF, outputNL = CRLF }
    cleanUp      = logNotice "talk cleanUp" ("closing the handle for " <> T.pack host <> ".") >> (liftIO . hClose $ h)


adHoc :: MsgQueue -> HostName -> MudStack (Id, Sing)
adHoc mq host = do
    (sexy, r) <- liftIO $ (,) <$> randomSex <*> randomRace
    modifyState $ \ms ->
        let i    = getUnusedId ms
            s    = showText r <> showText i
            e    = Ent { _entId    = i
                       , _entName  = Nothing
                       , _sing     = s
                       , _plur     = ""
                       , _entDesc  = capitalize $ mkThrPerPro sexy <> " is an ad-hoc player character."
                       , _entFlags = zeroBits }
            m    = Mob { _sex  = sexy
                       , _st   = 10
                       , _dx   = 10
                       , _iq   = 10
                       , _ht   = 10
                       , _hp   = 10
                       , _fp   = 10
                       , _xp   = 0
                       , _hand = RHand }
            pc   = PC  { _rmId       = iWelcome
                       , _race       = r
                       , _introduced = []
                       , _linked     = [] }
            pla  = Pla { _hostName   = host
                       , _plaFlags   = zeroBits
                       , _columns    = 80
                       , _pageLines  = 24
                       , _interp     = Just interpName
                       , _peepers    = []
                       , _peeping    = []
                       , _lastRmId   = Nothing }
            ms'  = ms  & entTbl .ind i .~ e
                       & typeTbl.ind i .~ PCType
            ris  = sortInv ms' $ getInv iWelcome ms' ++ [i]
            ms'' = ms' & coinsTbl   .ind i        .~ mempty
                       & eqTbl      .ind i        .~ M.empty
                       & invTbl     .ind i        .~ []
                       & invTbl     .ind iWelcome .~ ris
                       & mobTbl     .ind i        .~ m
                       & msgQueueTbl.ind i        .~ mq
                       & pcTbl      .ind i        .~ pc
                       & plaTbl     .ind i        .~ pla
        in (ms'', (i, s))


randomSex :: IO Sex
randomSex = ([ Male, Female ] !!) . fromEnum <$> (randomIO :: IO Bool)


randomRace :: IO Race
randomRace = randomIO


getUnusedId :: MudState -> Id
getUnusedId = views typeTbl (head . ([0..] \\) . IM.keys)


plaThreadExHandler :: T.Text -> Id -> SomeException -> MudStack ()
plaThreadExHandler threadName i e
  | Just ThreadKilled <- fromException e = closePlaLog i
  | otherwise                            = threadExHandler threadName e


dumpTitle :: MsgQueue -> MudStack ()
dumpTitle mq = liftIO mkFilename >>= try . takeADump >>= eitherRet (fileIOExHandler "dumpTitle")
  where
    mkFilename   = ("title" ++) . show <$> randomRIO (1, noOfTitles)
    takeADump fn = send mq . nlPrefix . nl =<< (liftIO . T.readFile $ titleDir </> fn)


-- ==================================================
-- "Inactivity timer" threads:


type InacTimerQueue = TMQueue InacTimerMsg


data InacTimerMsg = ResetTimer


inacTimer :: Id -> MsgQueue -> InacTimerQueue -> MudStack ()
inacTimer i mq itq = sequence_ [ setThreadType . InacTimer $ i, loop 0 `catch` plaThreadExHandler "inactivity timer" i ]
  where
    loop secs = do
        liftIO . threadDelay $ 1 * 10 ^ 6
        itq |$| liftIO . atomically . tryReadTMQueue >=> \case
          Just Nothing | secs >= maxInacSecs -> inacBoot secs
                       | otherwise           -> loop . succ $ secs
          Just (Just ResetTimer)             -> loop 0
          Nothing                            -> return ()
    inacBoot (parensQuote . T.pack . renderSecs -> secs) = getState >>= \ms -> let s = getSing i ms in do
        logPla "inacTimer" i $ "booted due to inactivity " <> secs <>  "."
        logNotice "inacTimer" . T.concat $ [ "booting player ", showText i, " ", parensQuote s, " due to inactivity." ]
        liftIO . atomically . writeTQueue mq $ InacBoot


-- ==================================================
-- "Server" threads:


server :: Handle -> Id -> MsgQueue -> InacTimerQueue -> MudStack ()
server h i mq itq = sequence_ [ setThreadType . Server $ i, loop `catch` plaThreadExHandler "server" i ]
  where
    loop = mq |$| liftIO . atomically . readTQueue >=> \case
      Dropped        ->                                  sayonara
      FromClient msg -> handleFromClient i mq itq msg >> loop
      FromServer msg -> handleFromServer i h msg      >> loop
      InacBoot       -> sendInacBootMsg h             >> sayonara
      InacStop       -> stopInacThread itq            >> loop
      MsgBoot msg    -> sendBootMsg h msg             >> sayonara
      Peeped  msg    -> (liftIO . T.hPutStr h $ msg)  >> loop
      Prompt  p      -> sendPrompt i h p              >> loop
      Quit           -> cowbye h                      >> sayonara
      Shutdown       -> shutDown                      >> loop
      SilentBoot     ->                                  sayonara
    sayonara = sequence_ [ stopInacThread itq, handleEgress i ]


handleFromClient :: Id -> MsgQueue -> InacTimerQueue -> T.Text -> MudStack ()
handleFromClient i mq itq (T.strip . stripControl . stripTelnet -> msg) = getState >>= \ms ->
    let p           = getPla i ms
        thruCentral = unless (T.null msg) . uncurry (interpret p centralDispatch) . headTail . T.words $ msg
        thruOther f = uncurry (interpret p f) (T.null msg ? ("", []) :? (headTail . T.words $ msg))
    in maybe thruCentral thruOther $ p^.interp
  where
    interpret p f cn as = do
        forwardToPeepers i (p^.peepers) FromThePeeped msg
        liftIO . atomically . writeTMQueue itq $ ResetTimer
        f cn . WithArgs i mq (p^.columns) $ as


forwardToPeepers :: Id -> Inv -> ToOrFromThePeeped -> T.Text -> MudStack ()
forwardToPeepers i peeperIds toOrFrom msg = liftIO . atomically . helperSTM =<< getState
  where
    helperSTM ms = forM_ [ getMsgQueue peeperId ms | peeperId <- peeperIds ]
                         (`writeTQueue` (mkPeepedMsg . getSing i $ ms))
    mkPeepedMsg s = Peeped $ case toOrFrom of
      ToThePeeped   ->      T.concat   [ toPeepedColor,   " ", bracketQuote s, " ", dfltColor, " ", msg ]
      FromThePeeped -> nl . T.concat $ [ fromPeepedColor, " ", bracketQuote s, " ", dfltColor, " ", msg ]


handleFromServer :: Id -> Handle -> T.Text -> MudStack ()
handleFromServer i h msg = getState >>= \ms -> let peeps = getPeepers i ms in
    forwardToPeepers i peeps ToThePeeped msg >> (liftIO . T.hPutStr h $ msg)


sendInacBootMsg :: Handle -> MudStack ()
sendInacBootMsg h = liftIO . T.hPutStrLn h . nl $ bootMsg
  where
    bootMsg = bootMsgColor <> "You are being disconnected from CurryMUD due to inactivity." <> dfltColor


stopInacThread :: InacTimerQueue -> MudStack ()
stopInacThread = liftIO . atomically . closeTMQueue


sendBootMsg :: Handle -> T.Text -> MudStack ()
sendBootMsg h = liftIO . T.hPutStrLn h . nl . (<> dfltColor) . (bootMsgColor <>)


sendPrompt :: Id -> Handle -> T.Text -> MudStack ()
sendPrompt i h = handleFromServer i h . nl


cowbye :: Handle -> MudStack ()
cowbye h = liftIO takeADump `catch` fileIOExHandler "cowbye"
  where
    takeADump = T.hPutStrLn h =<< T.readFile cowbyeFile


shutDown :: MudStack ()
shutDown = do
    massMsg SilentBoot
    onEnv $ liftIO . void . forkIO . runReaderT commitSuicide
  where
    commitSuicide = do
        liftIO . mapM_ wait . M.elems . view talkAsyncTbl =<< getState
        logNotice "shutDown commitSuicide" "all players have been disconnected."
        persist
        logNotice "shutDown commitSuicide" "killing the listen thread."
        liftIO . killThread . getListenThreadId =<< getState


-- ==================================================
-- "Receive" threads:


receive :: Handle -> Id -> MsgQueue -> MudStack ()
receive h i mq = sequence_ [ setThreadType . Receive $ i, loop `catch` plaThreadExHandler "receive" i ]
  where
    loop = mIf (liftIO . hIsEOF $ h)
               (sequence_ [ logPla "receive" i "connection dropped."
                          , liftIO . atomically . writeTQueue mq $ Dropped ])
               (sequence_ [ liftIO $ atomically . writeTQueue mq . FromClient . remDelimiters =<< T.hGetLine h
                          , loop ])
    remDelimiters = T.foldr helper ""
    helper c acc | T.singleton c `notInfixOf` delimiters = c `T.cons` acc
                 | otherwise                             = acc
    delimiters = T.pack [ stdDesigDelimiter, nonStdDesigDelimiter, desigDelimiter ]
