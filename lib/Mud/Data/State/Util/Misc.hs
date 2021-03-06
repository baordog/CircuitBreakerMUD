{-# LANGUAGE FlexibleContexts, LambdaCase, NamedFieldPuns, OverloadedStrings, TransformListComp, TupleSections, ViewPatterns #-}

-- This module contains state-related functions used by multiple modules.

module Mud.Data.State.Util.Misc ( addToInv
                                , BothGramNos
                                , dropPrefixes
                                , dropPrefixesForHooks
                                , findInvContaining
                                , findMobIds
                                , getAdminIds
                                , getBothGramNos
                                , getEffBothGramNos
                                , getEffName
                                , getFeelingFun
                                , getFun
                                , getHookFun
                                , getIdForMobSing
                                , getInstaEffectFun
                                , getLogAsyncs
                                , getLoggedInAdminIds
                                , getLoggedInPlaIds
                                , getMobRmNonIncogInvCoins
                                , getNonIncogInv
                                , getNonIncogInvCoins
                                , getNonIncogLoggedInAdminIds
                                , getNpcIds
                                , getRmActionFun
                                , getState
                                , getUnusedId
                                , isKnownLang
                                , isLoggedIn
                                , isNpc
                                , isPC
                                , lookupHooks
                                , mkAdminIdSingList
                                , mkAdminPlaIdSingList
                                , mkCapsFun
                                , mkCoinsMsgs
                                , mkMobRmDesc
                                , mkNameCountBothList
                                , mkPlaIdSingList
                                , mkPlurFromBoth
                                , mkSerializedNonStdDesig
                                , mkStdDesig
                                , mkUnknownPCEntName
                                , modifyState
                                , onEnv
                                , pcNpc
                                , pluralize
                                , procHooks
                                , procQuoteChars
                                , raceToLang
                                , removeAdHoc
                                , renderLiqNoun
                                , renderNoun
                                , runEffectFun
                                , setInterp
                                , sortInv
                                , tweak
                                , tweaks
                                , withLock ) where

import Mud.Data.Misc
import Mud.Data.State.MudData
import Mud.Data.State.Util.Get
import Mud.Data.State.Util.Hierarchy
import Mud.TheWorld.Zones.AdminZoneIds (iWelcome)
import Mud.TopLvlDefs.Chars
import Mud.TopLvlDefs.Misc
import Mud.Util.List hiding (countOcc)
import Mud.Util.Misc hiding (blowUp, patternMatchFail)
import Mud.Util.Operators
import Mud.Util.Quoting
import Mud.Util.Text
import qualified Mud.Util.Misc as U (blowUp, patternMatchFail)

import Control.Arrow ((***))
import Control.Concurrent.STM (atomically)
import Control.Concurrent.STM.TMVar (putTMVar, takeTMVar)
import Control.Exception.Lifted (bracket)
import Control.Lens (_1, _2, at, both, over, to, view, views)
import Control.Lens.Operators ((%~), (&), (.~), (^.))
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask)
import Data.IntMap.Lazy ((!))
import Data.IORef (atomicModifyIORef', readIORef)
import Data.List ((\\), delete, foldl', nub, sortBy)
import Data.Maybe (catMaybes, fromJust, fromMaybe)
import Data.Monoid (Sum(..), (<>))
import Data.Text (Text)
import GHC.Exts (sortWith)
import qualified Data.IntMap.Lazy as IM (filter, keys, toList)
import qualified Data.Map.Lazy as M (lookup)
import qualified Data.Text as T
import qualified Data.Vector.Unboxed as V (Vector)
import Text.Regex.Posix ((=~))


{-# ANN module ("HLint: ignore Use &&" :: String) #-}


-----


blowUp :: BlowUp a
blowUp = U.blowUp "Mud.Data.State.Util.Misc"


patternMatchFail :: (Show a) => PatternMatchFail a b
patternMatchFail = U.patternMatchFail "Mud.Data.State.Util.Misc"


-- ==================================================


addToInv :: MudState -> Inv -> Inv -> Inv
addToInv ms addThese toThese = sortInv ms $ toThese ++ addThese


-----


findInvContaining :: Id -> MudState -> Maybe Id
findInvContaining i ms = let matches = views invTbl (IM.keys . IM.filter (i `elem`)) ms
                         in ()# matches ? Nothing :? Just (head matches)


-----


findMobIds :: MudState -> Inv -> Inv
findMobIds ms haystack = [ i | i <- haystack
                             , uncurry (||) . ((PCType |&|) *** (NpcType |&|)) . over both (==) . dup . getType i $ ms ]


-----


getAdminIds :: MudState -> Inv
getAdminIds = getAdminIdsHelper (const True)


getAdminIdsHelper :: (Pla -> Bool) -> MudState -> Inv
getAdminIdsHelper f = IM.keys . IM.filter (uncurry (&&) . (isAdmin *** f) . dup) . view plaTbl


-----


type BothGramNos = (Sing, Plur)


getBothGramNos :: Id -> MudState -> BothGramNos
getBothGramNos i = (view sing *** view plur) . dup . getEnt i


getEffBothGramNos :: Id -> MudState -> Id -> BothGramNos
getEffBothGramNos i ms targetId =
    let targetEnt  = getEnt targetId ms
        targetSing = targetEnt^.sing
    in case targetEnt^.entName of
      Nothing -> let (pp *** pp -> (targetSexy, targetRace)) = getSexRace targetId ms
                 in if targetSing `elem` getIntroduced i ms
                   then (targetSing, "")
                   else (targetRace, plurRace targetRace) & both %~ ((targetSexy <>) . (" " <>))
      Just {} -> (targetSing, targetEnt^.plur)
  where
    plurRace "dwarf" = "dwarves"
    plurRace "elf"   = "elves"
    plurRace r       = r <> "s"


-----


getEffName :: Id -> MudState -> Id -> Text
getEffName i ms targetId = let targetEnt = getEnt targetId ms
                           in fromMaybe (helper $ targetEnt^.sing) $ targetEnt^.entName
  where
    helper targetSing
      | isNpc i ms || views (pcTbl.ind i.introduced) (targetSing `notElem`) ms = mkUnknownPCEntName targetId ms
      | otherwise                                                              = uncapitalize targetSing


mkUnknownPCEntName :: Id -> MudState -> Text
mkUnknownPCEntName i ms = views entName (fromMaybe helper) . getEnt i $ ms
  where
    helper = let (T.head . pp *** pp -> (h, r)) = getSexRace i ms in h `T.cons` r


-----


getFeelingFun :: FeelingTag -> MudState -> FeelingFun
getFeelingFun tag = views (feelingFunTbl.at tag) (fromMaybe oops)
  where
    oops = blowUp "getFeelingFun" "Feeling tag not found in function table" tag


-----


getFun :: FunName -> MudState -> Fun
getFun n = views (funTbl.at n) (fromMaybe oops)
  where
    oops = blowUp "getFun" "Function name not found in function table" n


-----


getHookFun :: HookName -> MudState -> HookFun
getHookFun n = views (hookFunTbl.at n) (fromMaybe oops)
  where
    oops = blowUp "getHookFun" "Hook name not found in hook function table" n


-----


getIdForMobSing :: Sing -> MudState -> Id
getIdForMobSing s ms = let [(i, _)] = views entTbl (IM.toList . IM.filter (views sing (== s))) ms in i


-----


getInstaEffectFun :: FunName -> MudState -> InstaEffectFun
getInstaEffectFun n = views (instaEffectFunTbl.at n) (fromMaybe oops)
  where
    oops = blowUp "getInstaEffectFun" "Function name not found in instantaneous effect function table" n


-----


getLogAsyncs :: MudData -> (LogAsync, LogAsync)
getLogAsyncs = (getAsync noticeLog *** getAsync errorLog) . dup
  where
    getAsync = flip views (fst . fromJust)


-----


getLoggedInAdminIds :: MudState -> Inv
getLoggedInAdminIds = getAdminIdsHelper isLoggedIn


getLoggedInPlaIds :: MudState ->  Inv
getLoggedInPlaIds = views plaTbl (IM.keys . IM.filter (uncurry (&&) . (isLoggedIn *** not . isAdmin) . dup))


-----


getMobRmNonIncogInvCoins :: Id -> MudState -> (Inv, Coins)
getMobRmNonIncogInvCoins i ms = let ri = getRmId i ms in getNonIncogInvCoins ri ms


-----


getNonIncogInv :: Id -> MudState -> Inv
getNonIncogInv i ms = filter notIncog . getInv i $ ms
  where
    notIncog targetId | getType targetId ms /= PCType     = True
                      | not . isIncognitoId targetId $ ms = True
                      | otherwise                         = False


-----


getNonIncogInvCoins :: Id -> MudState -> (Inv, Coins)
getNonIncogInvCoins i = (getNonIncogInv i *** getCoins i) . dup


-----


getNonIncogLoggedInAdminIds :: MudState -> Inv
getNonIncogLoggedInAdminIds ms = let adminIds = getLoggedInAdminIds ms
                                 in [ adminId | adminId <- adminIds, not . isIncognitoId adminId $ ms ]


-----


getNpcIds :: MudState -> Inv
getNpcIds = views npcTbl IM.keys


-----


getRmActionFun :: FunName -> MudState -> RmActionFun
getRmActionFun n = views (rmActionFunTbl.at n) (fromMaybe oops)
  where
    oops = blowUp "getRmActionFun" "Function name not found in room action function table" n


-----


getState :: MudStack MudState
getState = onEnv $ liftIO . readIORef . view mudStateIORef


onEnv :: (MudData -> MudStack a) -> MudStack a
onEnv = (ask >>=)


-----


getUnusedId :: MudState -> Id
getUnusedId = views typeTbl (head . (enumFrom 0 \\) . IM.keys)


-----


isKnownLang :: Id -> MudState -> Lang -> Bool
isKnownLang i ms lang | lang == CommonLang = True
                      | otherwise          = lang `elem` getKnownLangs i ms


-----


isLoggedIn :: Pla -> Bool
isLoggedIn = views lastRmId ((()#) . (Sum <$>))


-----


lookupHooks :: Id -> MudState -> CmdName -> Maybe [Hook]
lookupHooks i ms cn = views rmHookMap (M.lookup cn) . getMobRm i $ ms


-----


mkAdminIdSingList :: MudState -> [(Id, Sing)]
mkAdminIdSingList = mkIdSingListHelper id


mkIdSingListHelper :: (Bool -> Bool) -> MudState -> [(Id, Sing)]
mkIdSingListHelper f ms@(view plaTbl -> pt) = [ (i, s) | i <- IM.keys pt
                                                       , f . isAdmin $ pt ! i
                                                       , let s = getSing i ms
                                                       , then sortWith by s ]


-----


mkAdminPlaIdSingList :: MudState -> [(Id, Sing)]
mkAdminPlaIdSingList = mkIdSingListHelper (const True)


-----


mkCoinsMsgs :: (Int -> Text -> Text) -> Coins -> [Text]
mkCoinsMsgs f (Coins (cop, sil, gol)) = catMaybes [ c, s, g ]
  where
    c = Sum cop |!| Just . f cop $ "copper piece"
    s = Sum sil |!| Just . f sil $ "silver piece"
    g = Sum gol |!| Just . f gol $ "gold piece"


-----


mkMobRmDesc :: Id -> MudState -> Text
mkMobRmDesc i ms | hasMobId i ms = case getMobRmDesc i ms of Nothing   -> ""
                                                             Just desc -> parensQuote desc
                 | otherwise     = ""


-----


mkNameCountBothList :: Id -> MudState -> Inv -> [(Text, Int, BothGramNos)]
mkNameCountBothList i ms targetIds = let ens   = [ getEffName        i ms targetId | targetId <- targetIds ]
                                         cs    = mkCountList ebgns
                                         ebgns = [ getEffBothGramNos i ms targetId | targetId <- targetIds ]
                                     in nub . zip3 ens cs $ ebgns


-----


mkPlaIdSingList :: MudState -> [(Id, Sing)]
mkPlaIdSingList = mkIdSingListHelper not


-----


mkPlurFromBoth :: BothGramNos -> Plur
mkPlurFromBoth (s, "") = s <> "s"
mkPlurFromBoth (_, p ) = p


-----


mkSerializedNonStdDesig :: Id -> MudState -> Sing -> AOrThe -> ShouldCap -> Text
mkSerializedNonStdDesig i ms s aot (mkCapsFun -> f) =
    serialize NonStdDesig { dEntSing = s, dDesc = helper }
  where
    helper | isPC i ms = g $ let (pp *** pp -> (sexy, r)) = getSexRace i ms in sexy <> " " <> r
           | otherwise = onFalse (isCapital s) g s
    g = f . (pp aot <>) . (" " <>)


mkCapsFun :: ShouldCap -> Text -> Text
mkCapsFun = \case DoCap    -> capitalize
                  Don'tCap -> id


-----


mkStdDesig :: Id -> MudState -> ShouldCap -> Desig
mkStdDesig i ms sc = StdDesig { desigEntSing   = Just . getSing i $ ms
                              , desigShouldCap = sc
                              , desigEntName   = views entName (fromMaybe (mkUnknownPCEntName i ms)) . getEnt i $ ms
                              , desigId        = i
                              , desigIds       = findMobIds ms . getMobRmInv i $ ms }


-----


modifyState :: (MudState -> (MudState, a)) -> MudStack a
modifyState f = ask >>= \md -> liftIO .  atomicModifyIORef' (md^.mudStateIORef) $ f


-----


pcNpc :: Id -> MudState -> Fun -> Fun -> MudStack ()
pcNpc i ms a b = case getType i ms of
  PCType  -> a
  NpcType -> b
  t       -> patternMatchFail "pcNpc" . showText $ t


-----


pluralize :: BothGramNos -> Int -> Text
pluralize (s, p) x = x == 1 ? s :? p


-----


procHooks :: Id -> MudState -> V.Vector Int -> CmdName -> Args -> HookFunRes
procHooks i ms v cn as | initAcc <- (as, (ms, [], [], []), []) = case lookupHooks i ms cn of
  Nothing    -> initAcc
  Just hooks -> case as of
    -- Process hooks that match on a particular argument. These hooks need to see the other argument(s) passed as well,
    -- not just the argument that matches the hook's trigger.
    [arg] | delim <- T.singleton hookArgDelimiter
          , delim `T.isInfixOf` arg
          , (dropPrefixes -> a, T.tail -> rest) <- T.breakOn delim arg
          -> case filter (\Hook { hookTriggers } -> a `elem` hookTriggers) hooks of
               []  -> initAcc
               [h] -> getHookFun (hookName h) ms i h v (initAcc & _1 .~ pure rest)
               xs  -> patternMatchFail "procHooks" . showText $ xs
    -- Process hooks whose triggers match on any single argument.
    _ -> let helper acc arg = case filter (\Hook { hookTriggers } -> arg `elem` hookTriggers) hooks of
               []        -> acc
               (match:_) -> acc ++ pure match
             as' = dropPrefixesForHooks hooks as
         in case foldl' helper [] as' of
           []      -> initAcc
           matches ->
             let xformedArgs = foldr (\Hook { hookTriggers } -> dropSynonyms hookTriggers) as' matches
                 hookHelper a@(_, (ms', _, _, _), _) h = getHookFun (hookName h) ms' i h v a
             in foldl' hookHelper (initAcc & _1 .~ xformedArgs) . nub $ matches


dropPrefixesForHooks :: [Hook] -> Args -> Args
dropPrefixesForHooks hs = let helper _     []     = []
                              helper trigs (a:as) | a' <- dropPrefixes a, a' `elem` trigs = a' : rest
                                                  | otherwise                             = a  : rest
                                where
                                  rest = helper trigs as
                          in helper (concatMap hookTriggers hs)


dropPrefixes :: Text -> Text
dropPrefixes     (T.uncons -> Just (x, xs)) | x == allChar, ()!# xs = xs
dropPrefixes arg@(T.unpack -> arg'        )
  | triple@(_, _, c) <- arg' =~ mkRegex indexChar,  isMatch triple = T.pack c
  | triple@(_, _, c) <- arg' =~ mkRegex amountChar, isMatch triple = T.pack c
  | otherwise                                                      = arg
  where
    isMatch :: (String, String, String) -> Bool
    isMatch (a, b, c) = and [ ()# a, ()!# b, ()!# c ]
    mkRegex c         = "^[0-9]+\\" ++ pure c :: String


-----


procQuoteChars :: Args -> Maybe Args
procQuoteChars []                    = Just []
procQuoteChars as@(T.unwords -> txt) | not $ q `T.isInfixOf` txt = Just as
                                     | odd . countOcc q $ txt    = Nothing
                                     | otherwise = Just [ fillerToSpcs w | w <- T.words . helper $ txt ]
  where
    q         = T.singleton quoteChar
    helper "" = ""
    helper t  | q `T.isInfixOf` t = let (left,   T.tail -> rest ) = T.breakOn q t
                                        (quoted, T.tail -> right) = T.breakOn q rest
                                    in left <> spcsToFiller quoted <> helper right
              | otherwise         = t


-----


raceToLang :: Race -> Lang
raceToLang Dwarf     = DwarfLang
raceToLang Elf       = ElfLang
raceToLang Felinoid  = FelinoidLang
raceToLang Hobbit    = HobbitLang
raceToLang Human     = HumanLang
raceToLang Lagomorph = LagomorphLang
raceToLang Nymph     = NymphLang
raceToLang Vulpenoid = VulpenoidLang


-----


removeAdHoc :: Id -> MudState -> MudState
removeAdHoc i ms = ms & activeEffectsTbl.at  i        .~ Nothing
                      & coinsTbl        .at  i        .~ Nothing
                      & entTbl          .at  i        .~ Nothing
                      & eqTbl           .at  i        .~ Nothing
                      & invTbl          .at  i        .~ Nothing
                      & invTbl          .ind iWelcome %~ (i `delete`)
                      & mobTbl          .at  i        .~ Nothing
                      & msgQueueTbl     .at  i        .~ Nothing
                      & pausedEffectsTbl.at  i        .~ Nothing
                      & pcTbl           .at  i        .~ Nothing
                      & plaTbl          .at  i        .~ Nothing
                      & rndmNamesMstrTbl.at  i        .~ Nothing
                      & teleLinkMstrTbl .at  i        .~ Nothing
                      & typeTbl         .at  i        .~ Nothing


-----


renderNoun :: (Text -> Text) -> Noun -> Text
renderNoun _ (Don'tArticle t) = t
renderNoun f (DoArticle    t) = f t


renderLiqNoun :: Liq -> (Text -> Text) -> Text
renderLiqNoun l f = l^.liqNoun.to (renderNoun f)


-----


runEffectFun :: FunName -> Id -> Seconds -> MudStack ()
runEffectFun n i secs = views (effectFunTbl.at n) (maybe oops (\f -> f i secs)) =<< getState
  where
    oops = blowUp "runEffectFun" "Function name not found in effect function table" n


-----


setInterp :: Id -> Maybe Interp -> MudStack ()
setInterp i mi = tweak $ mobTbl.ind i.interp .~ mi


-----


sortInv :: MudState -> Inv -> Inv
sortInv ms is = let (foldr helper dupIdentity -> (pcs, others)) = [ (i, getType i ms) | i <- is ]
                in (pcs ++) . sortOthers $ others
  where
    helper (i, t) acc                  = let consTo lens = acc & lens %~ (i :)
                                         in t == PCType ? consTo _1 :? consTo _2
    sortOthers                         = select _1 . sortBy nameThenSing . zipped
    nameThenSing (_, n, s) (_, n', s') = (n `compare` n') <> (s `compare` s')
    zipped others                      = [ (i, views entName fromJust e, e^.sing) | i <- others
                                                                                  , let e = getEnt i ms ]


-----


tweak :: (MudState -> MudState) -> MudStack ()
tweak f = modifyState $ (, ()) . f


tweaks :: [MudState -> MudState] -> MudStack ()
tweaks fs = tweak $ \ms -> foldl' (&) ms fs


-----


withLock :: Lock -> IO () -> IO ()
withLock l f = bracket (atomically . takeTMVar $ l)
                       (\Done -> atomically . putTMVar l $ Done)
                       (\Done -> f)
