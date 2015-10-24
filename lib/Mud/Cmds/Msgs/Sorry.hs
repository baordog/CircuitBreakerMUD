{-# LANGUAGE LambdaCase, OverloadedStrings, RecordWildCards, ViewPatterns #-}

module Mud.Cmds.Msgs.Sorry  ( sorryAdminChanTargetName
                            , sorryAdminName
                            , sorryBanAdmin
                            , sorryBanSelf
                            , sorryBootSelf
                            , sorryBracketedMsg
                            , sorryChanIncog
                            , sorryChanMsg
                            , sorryChanName
                            , sorryChanNoOneListening
                            , sorryChanTargetName
                            , sorryChanTargetNameFromContext
                            , sorryCon
                            , sorryConInEq
                            , sorryConnectIgnore
                            , sorryDisconnectIgnore
                            , sorryDropInEq
                            , sorryDropInRm
                            , sorryEmoteExcessTargets
                            , sorryEmoteTargetCoins
                            , sorryEmoteTargetInEq
                            , sorryEmoteTargetInInv
                            , sorryEmoteTargetRmOnly
                            , sorryEmoteTargetType
                            , sorryEquipCoins
                            , sorryEquipInvLook
                            , sorryExpCmdCoins
                            , sorryExpCmdIllegalTarget
                            , sorryExpCmdInInvEq
                            , sorryExpCmdLen
                            , sorryExpCmdName
                            , sorryExpCmdRequiresTarget
                            , sorryExpCmdTargetType
                            , sorryGetEnc
                            , sorryGetType
                            , sorryHostIgnore
                            , sorryIgnoreLocPref
                            , sorryIgnoreLocPrefPlur
                            , sorryIncog
                            , sorryIndent
                            , sorryInterpNameAlreadyTaken
                            , sorryInterpNameBanned
                            , sorryInterpNameExcessArgs
                            , sorryInterpNameIllegal
                            , sorryInterpNameLen
                            , sorryLoggedOut
                            , sorryMsgIncog
                            , sorryMyChansIgnore
                            , sorryNameTaken
                            , sorryNewChanExisting
                            , sorryNewChanName
                            , sorryNoConHere
                            , sorryNoLinks
                            , sorryNoOneHere
                            , sorryParseArg
                            , sorryParseBase
                            , sorryParseChanId
                            , sorryParseId
                            , sorryParseIndent
                            , sorryParseInOut
                            , sorryParseLineLen
                            , sorryParseNum
                            , sorryParseSetting
                            , sorryPCName
                            , sorryPCNameLoggedIn
                            , sorryPeepAdmin
                            , sorryPeepIgnore
                            , sorryPeepSelf
                            , sorryPutExcessCon
                            , sorryPutInCoin
                            , sorryPutInEq
                            , sorryPutInRm
                            , sorryPutInsideSelf
                            , sorryQuitCan'tAbbrev
                            , sorryReadyAlreadyWearing
                            , sorryReadyAlreadyWielding
                            , sorryReadyAlreadyWieldingTwoHanded
                            , sorryReadyAlreadyWieldingTwoWpns
                            , sorryReadyClothFull
                            , sorryReadyClothFullOneSide
                            , sorryReadyCoins
                            , sorryReadyInEq
                            , sorryReadyInRm
                            , sorryReadyRol
                            , sorryReadyType
                            , sorryReadyWpnHands
                            , sorryReadyWpnRol
                            , sorryRegPlaName
                            , sorryRemCoin
                            , sorryRemEmpty
                            , sorryRemExcessCon
                            , sorryRemIgnore
                            , sorrySayCoins
                            , sorrySayExcessTargets
                            , sorrySayInEq
                            , sorrySayInInv
                            , sorrySayNoOneHere
                            , sorrySayTargetType
                            , sorrySearch
                            , sorrySetName
                            , sorrySetRange
                            , sorryShowExcessTargets
                            , sorryShowInRm
                            , sorryShowTarget
                            , sorrySudoerDemoteRoot
                            , sorrySudoerDemoteSelf
                            , sorryTeleAlreadyThere
                            , sorryTelePlaSelf
                            , sorryTeleRmName
                            , sorryTunedOutChan
                            , sorryTunedOutICChan
                            , sorryTunedOutOOCChan
                            , sorryTunedOutPCSelf
                            , sorryTunedOutPCTarget
                            , sorryTuneName
                            , sorryTwoWayLink
                            , sorryTwoWayTargetName
                            , sorryUnlinkIgnore
                            , sorryUnlinkName
                            , sorryUnreadyCoins
                            , sorryUnreadyInInv
                            , sorryUnreadyInRm
                            , sorryWrapLineLen
                            , sorryWtf ) where

import Mud.Cmds.Util.CmdPrefixes
import Mud.Data.Misc
import Mud.Data.State.MudData
import Mud.Misc.ANSI
import Mud.TopLvlDefs.Chars
import Mud.TopLvlDefs.Misc
import Mud.Util.Quoting
import Mud.Util.Text
import qualified Mud.Util.Misc as U (patternMatchFail)

import Data.Char (toLower)
import Data.Monoid ((<>))
import qualified Data.Text as T


{-# ANN module ("HLint: ignore Use camelCase" :: String) #-}


-----


patternMatchFail :: T.Text -> [T.Text] -> a
patternMatchFail = U.patternMatchFail "Mud.Cmds.Msgs.Sorry"


-- ==================================================


sorryIgnoreLocPref :: T.Text -> T.Text
sorryIgnoreLocPref msg = parensQuote $ msg <> " need not be given a location prefix. The location prefix you provided \
                                              \will be ignored."


sorryIgnoreLocPrefPlur :: T.Text -> T.Text
sorryIgnoreLocPrefPlur msg = parensQuote $ msg <> " need not be given location prefixes. The location prefixes you \
                                                  \provided will be ignored."


-----


sorryAdminChanTargetName :: T.Text -> T.Text
sorryAdminChanTargetName = sorryChanTargetName "admin"


-----


sorryAdminName :: T.Text -> T.Text
sorryAdminName n = "There is no administrator by the name of " <> dblQuote n <> "."


-----


sorryBanAdmin :: T.Text
sorryBanAdmin = "You can't ban an admin."


sorryBanSelf :: T.Text
sorryBanSelf = "You can't ban yourself."


-----


sorryBootSelf :: T.Text
sorryBootSelf = "You can't boot yourself."


-----


sorryBracketedMsg :: T.Text
sorryBracketedMsg = "You can't open or close your message with brackets."


-----


sorryChanIncog :: T.Text -> T.Text
sorryChanIncog t = "You can't send a message on " <> t <> " channel while incognito."


sorryChanMsg :: T.Text
sorryChanMsg = "You must also provide a message to send."


sorryChanName :: ChanName -> T.Text
sorryChanName cn = "You are not connected to a channel named " <> dblQuote cn <> "."


sorryChanNoOneListening :: T.Text -> T.Text
sorryChanNoOneListening t = "You are the only person tuned in to the " <> t <> " channel."


sorryChanTargetName :: T.Text -> T.Text -> T.Text
sorryChanTargetName cn n = T.concat [ "There is no one by the name of "
                                    , dblQuote n
                                    , " currently tuned in to the "
                                    , cn
                                    , " channel." ]


sorryChanTargetNameFromContext :: T.Text -> ChanContext -> T.Text
sorryChanTargetNameFromContext n (ChanContext { .. }) = sorryChanTargetName effChanName n
  where
    effChanName = maybe someCmdName dblQuote someChanName


-----


sorryCon :: Sing -> T.Text
sorryCon s = theOnLowerCap s <> " isn't a container."


sorryConInEq :: PutOrRem -> T.Text
sorryConInEq por = let (a, b) = expand por
                   in T.concat [ "Sorry, but you can't "
                               , a
                               , " an item "
                               , b
                               , " a container in your readied equipment. Please unready the container first." ]
  where
    expand = \case Put -> ("put",    "into")
                   Rem -> ("remove", "from")


-----


sorryConnectIgnore :: T.Text
sorryConnectIgnore = sorryIgnoreLocPrefPlur "The names of the people you would like to connect"


-----


sorryDisconnectIgnore :: T.Text
sorryDisconnectIgnore = sorryIgnoreLocPrefPlur "The names of the people you would like to disconnect"


-----


sorryDropInEq :: T.Text
sorryDropInEq = "Sorry, but you can't drop items in your readied equipment. Please unready the item(s) first."


sorryDropInRm :: T.Text
sorryDropInRm = "You can't drop an item that's already in your current room. If you're intent on dropping it, try \
                \picking it up first!"


-----


sorryEmoteExcessTargets :: T.Text
sorryEmoteExcessTargets = "Sorry, but you can only target one person at a time."


sorryEmoteTargetCoins :: T.Text
sorryEmoteTargetCoins = "You can't target coins."


sorryEmoteTargetInEq :: T.Text
sorryEmoteTargetInEq = "You can't target an item in your readied equipment."


sorryEmoteTargetInInv :: T.Text
sorryEmoteTargetInInv = "You can't target an item in your inventory."


sorryEmoteTargetRmOnly :: T.Text
sorryEmoteTargetRmOnly = "You can only target a person in your current room."


sorryEmoteTargetType :: Sing -> T.Text
sorryEmoteTargetType s = "You can't target " <> aOrAn s <> "."


-----


sorryEquipCoins :: T.Text
sorryEquipCoins = "You don't have any coins among your readied equipment."


-----


sorryEquipInvLook :: EquipInvLookCmd -> EquipInvLookCmd -> T.Text
sorryEquipInvLook a b = T.concat [ "You can only use the "
                                 , dblQuote . showText $ a
                                 , " command to examine items in your "
                                 , loc a
                                 , ". To examine items in your "
                                 , loc b
                                 , ", use the "
                                 , dblQuote . showText $ b
                                 , " command." ]
  where
    loc = \case EquipCmd -> "readied equipment"
                InvCmd   -> "inventory"
                LookCmd  -> "current room"


-----


sorryExpCmdCoins :: T.Text
sorryExpCmdCoins = "Sorry, but expressive commands cannot be used with coins."


sorryExpCmdInInvEq :: InInvEqRm -> T.Text
sorryExpCmdInInvEq loc = "You can't target an item in your " <> loc' <> " with an expressive command."
  where
    loc' = case loc of InEq  -> "readied equipment"
                       InInv -> "inventory"
                       _     -> patternMatchFail "sorryExpCmdInEqInv loc'" [ showText loc ]


sorryExpCmdLen :: T.Text
sorryExpCmdLen = "An expressive command sequence may not be more than 2 words long."


sorryExpCmdName :: T.Text -> T.Text
sorryExpCmdName cn = "There is no expressive command by the name of " <> dblQuote cn <> "."


sorryExpCmdIllegalTarget :: ExpCmdName -> T.Text
sorryExpCmdIllegalTarget cn =  "The " <> dblQuote cn <> " expressive command cannot be used with a target."


sorryExpCmdRequiresTarget :: ExpCmdName -> T.Text
sorryExpCmdRequiresTarget cn = "The " <> dblQuote cn <> " expressive command requires a single target."


sorryExpCmdTargetType :: T.Text
sorryExpCmdTargetType = "Sorry, but expressive commands can only target people."


-----


sorryGetEnc :: T.Text
sorryGetEnc = "You are too encumbered to pick up "


sorryGetType :: T.Text -> T.Text
sorryGetType t = "You can't pick up " <> t <> "."


-----


sorryHostIgnore :: T.Text
sorryHostIgnore = sorryIgnoreLocPrefPlur "The PC names of the players whose host statistics you would like to see"


-----


sorryIncog :: T.Text -> T.Text
sorryIncog cn = "You can't use the " <> dblQuote cn <> " command while incognito."


-----


sorryIndent :: T.Text
sorryIndent = "The indent amount must be less than the line length."


-----


sorryInterpNameAlreadyTaken :: Sing -> T.Text
sorryInterpNameAlreadyTaken s = dblQuote s <> " is already logged in."


sorryInterpNameBanned :: Sing -> T.Text
sorryInterpNameBanned s = T.concat [ bootMsgColor
                                   , s
                                   , " has been banned from CurryMUD!"
                                   , dfltColor ]


sorryInterpNameExcessArgs :: T.Text
sorryInterpNameExcessArgs = "Your name must be a single word."


sorryInterpNameIllegal :: T.Text
sorryInterpNameIllegal = "Your name cannot include any numbers or symbols."


sorryInterpNameLen :: T.Text
sorryInterpNameLen = T.concat [ "Your name must be between "
                              , minNameLenTxt
                              , " and "
                              , maxNameLenTxt
                              , " characters long." ]


-----


sorryLoggedOut :: Sing -> T.Text
sorryLoggedOut s = s <> " is not logged in."


-----


sorryMsgIncog :: T.Text
sorryMsgIncog = "You can't send a message to a player who is logged in while you are incognito."


-----


sorryMyChansIgnore :: T.Text
sorryMyChansIgnore = sorryIgnoreLocPrefPlur "The PC names of the players whose channel information you would like to \
                                            \see"


-----


sorryNameTaken :: T.Text
sorryNameTaken = "Sorry, but that name is already taken."


-----


sorryNewChanExisting :: ChanName -> T.Text
sorryNewChanExisting cn = "You are already connected to a channel named " <> dblQuote cn <> "."


sorryNewChanName :: T.Text -> T.Text -> T.Text
sorryNewChanName a msg = T.concat [ dblQuote a, " is not a legal channel name ", parensQuote msg, "." ]


-----


sorryNoConHere :: T.Text
sorryNoConHere = "You don't see any containers here."


sorryNoOneHere :: T.Text
sorryNoOneHere = "You don't see anyone here."


-----


sorryNoLinks :: T.Text
sorryNoLinks = "You haven't established a telepathic link with anyone."


-----


sorryPCName :: T.Text -> T.Text
sorryPCName n = "There is no PC by the name of " <> dblQuote n <> "."


sorryPCNameLoggedIn :: T.Text -> T.Text
sorryPCNameLoggedIn n = "No PC by the name of " <> dblQuote n <> " is currently logged in."


-----


sorryParseArg :: T.Text -> T.Text
sorryParseArg a = dblQuote a <> " is not a valid argument."


sorryParseBase :: T.Text -> T.Text
sorryParseBase t = dblQuote t <> " is not a valid base."


sorryParseChanId :: T.Text -> T.Text
sorryParseChanId a = dblQuote a <> " is not a valid channel ID."


sorryParseId :: T.Text -> T.Text
sorryParseId a = dblQuote a <> " is not a valid ID."


sorryParseInOut :: T.Text -> T.Text -> T.Text
sorryParseInOut value n = T.concat [ dblQuote value
                                   , " is not a valid value for the "
                                   , dblQuote n
                                   , " setting. Please specify one of the following: "
                                   , inOutOrOnOff
                                   , "." ]
  where
    inOutOrOnOff = T.concat [ dblQuote "in"
                            , "/"
                            , dblQuote "out"
                            , " or "
                            , dblQuote "on"
                            , "/"
                            , dblQuote "off" ]


sorryParseIndent :: T.Text -> T.Text
sorryParseIndent a = dblQuote a <> " is not a valid width amount."


sorryParseLineLen :: T.Text -> T.Text
sorryParseLineLen a = dblQuote a <> " is not a valid line length."


sorryParseNum :: T.Text -> T.Text -> T.Text
sorryParseNum numTxt base = T.concat [ dblQuote numTxt, " is not a valid number in base ", base, "." ]


sorryParseSetting :: T.Text -> T.Text -> T.Text
sorryParseSetting value name = T.concat [ dblQuote value, " is not a valid value for the ", dblQuote name, " setting." ]


-----


sorryPeepAdmin :: T.Text
sorryPeepAdmin = "You can't peep an admin."


sorryPeepIgnore :: T.Text
sorryPeepIgnore = sorryIgnoreLocPrefPlur "The PC names of the players you wish to start or stop peeping"


sorryPeepSelf :: T.Text
sorryPeepSelf = "You can't peep yourself."


-----


sorryPutExcessCon :: T.Text
sorryPutExcessCon = "You can only put things into one container at a time."


sorryPutInCoin :: T.Text
sorryPutInCoin = "You can't put something inside a coin."


sorryPutInEq :: T.Text
sorryPutInEq = "Sorry, but you can't put items in your readied equipment into a container. Please unready the item(s) \
               \first."


sorryPutInRm :: T.Text
sorryPutInRm = "Sorry, but you can't put items in your current room into a container. Please pick up the item(s) first."


sorryPutInsideSelf :: Sing -> T.Text
sorryPutInsideSelf s = "You can't put the " <> s <> " inside itself."


-----


sorryQuitCan'tAbbrev :: T.Text
sorryQuitCan'tAbbrev = T.concat [ "The "
                                , dblQuote "quit"
                                , " command may not be abbreviated. Type "
                                , dblQuote "quit"
                                , " with no arguments to quit CurryMUD." ]


-----


sorryReadyAlreadyWearing :: T.Text -> T.Text
sorryReadyAlreadyWearing t = "You're already wearing " <> aOrAn t <> "."


sorryReadyAlreadyWielding :: Sing -> Slot -> T.Text
sorryReadyAlreadyWielding s sl = T.concat [ "You're already wielding ", aOrAn s, " with your ", pp sl, "." ]


sorryReadyAlreadyWieldingTwoHanded :: T.Text
sorryReadyAlreadyWieldingTwoHanded = "You're already wielding a two-handed weapon."


sorryReadyAlreadyWieldingTwoWpns :: T.Text
sorryReadyAlreadyWieldingTwoWpns = "You're already wielding two weapons."


sorryReadyClothFull :: T.Text -> T.Text
sorryReadyClothFull t = "You can't wear any more " <> t <> "s."


sorryReadyClothFullOneSide :: Cloth -> Slot -> T.Text
sorryReadyClothFullOneSide (pp -> c) (pp -> s) = T.concat [ "You can't wear any more ", c, "s on your ", s, "." ]


sorryReadyCoins :: T.Text
sorryReadyCoins = "You can't ready coins."


sorryReadyInEq :: T.Text
sorryReadyInEq = "You can't ready an item that's already in your readied equipment."


sorryReadyInRm :: T.Text
sorryReadyInRm = "Sorry, but you can't ready items in your current room. Please pick up the item(s) first."


sorryReadyRol :: Sing -> RightOrLeft -> T.Text
sorryReadyRol s rol = T.concat [ "You can't wear ", aOrAn s, " on your ", pp rol, "." ]


sorryReadyType :: Sing -> T.Text
sorryReadyType s = "You can't ready " <> aOrAn s <> "."


sorryReadyWpnHands :: Sing -> T.Text
sorryReadyWpnHands s = "Both hands are required to wield the " <> s <> "."


sorryReadyWpnRol :: Sing -> T.Text
sorryReadyWpnRol s = "You can't wield " <> aOrAn s <> " with your finger!"


-----


sorryRegPlaName :: T.Text -> T.Text
sorryRegPlaName n = "There is no regular player by the name of " <> dblQuote n <> "."


-----


sorryRemCoin :: T.Text
sorryRemCoin = "You can't remove something from a coin."


sorryRemEmpty :: Sing -> T.Text
sorryRemEmpty s = "The " <> s <> " is empty."


sorryRemExcessCon :: T.Text
sorryRemExcessCon = "You can only remove things from one container at a time."


sorryRemIgnore :: T.Text
sorryRemIgnore = sorryIgnoreLocPrefPlur "The names of the items to be removed from a container "


-----


sorrySayCoins :: T.Text
sorrySayCoins = "You're talking to coins now?"


sorrySayExcessTargets :: T.Text
sorrySayExcessTargets = "Sorry, but you can only say something to one person at a time."


sorrySayInEq :: T.Text
sorrySayInEq = "You can't talk to an item in your readied equipment. Try saying something to someone in your current \
               \room."


sorrySayInInv :: T.Text
sorrySayInInv = "You can't talk to an item in your inventory. Try saying something to someone in your current room."


sorrySayNoOneHere :: T.Text
sorrySayNoOneHere = "You don't see anyone here to talk to."


sorrySayTargetType :: Sing -> T.Text
sorrySayTargetType s = "You can't talk to " <> aOrAn s <> "."


-----


sorrySearch :: T.Text
sorrySearch = "No matches found."


-----


sorrySetName :: T.Text -> T.Text
sorrySetName n = dblQuote n <> " is not a valid setting name."


sorrySetRange :: T.Text -> Int -> Int -> T.Text
sorrySetRange settingName minVal maxVal = T.concat [ capitalize settingName
                                                   , " must be between "
                                                   , showText minVal
                                                   , " and "
                                                   , showText maxVal
                                                   , "." ]


-----


sorryShowExcessTargets :: T.Text
sorryShowExcessTargets = "Sorry, but you can only show something to one person at a time."


sorryShowInRm :: T.Text
sorryShowInRm = "You can't show an item in your current room."


sorryShowTarget :: T.Text -> T.Text
sorryShowTarget t = "You can't show something to " <> aOrAn t <> "."


-----


sorrySudoerDemoteRoot :: T.Text
sorrySudoerDemoteRoot = "You can't demote Root."


sorrySudoerDemoteSelf :: T.Text
sorrySudoerDemoteSelf = "You can't demote yourself."


-----


sorryTeleAlreadyThere :: T.Text
sorryTeleAlreadyThere = "You're already there!"


sorryTelePlaSelf :: T.Text
sorryTelePlaSelf = "You can't teleport to yourself."


sorryTeleRmName :: T.Text -> T.Text
sorryTeleRmName n = T.concat [ dblQuote n
                             , " is not a valid room name. Type "
                             , quoteColor
                             , prefixAdminCmd "telerm"
                             , dfltColor
                             , " with no arguments to get a list of valid room names." ]


-----


sorryTuneName :: T.Text -> T.Text
sorryTuneName n = "You don't have a connection by the name of " <> dblQuote n <> "."


-----


sorryTunedOutICChan :: ChanName -> T.Text
sorryTunedOutICChan = sorryTunedOutChan "tune" . dblQuote


sorryTunedOutChan :: CmdName -> T.Text -> T.Text
sorryTunedOutChan x y = T.concat [ "You have tuned out the "
                                 , y
                                 , " channel. Type "
                                 , quoteColor
                                 , x
                                 , " "
                                 , y
                                 , "=in"
                                 , dfltColor
                                 , " to tune it back in." ]


sorryTunedOutOOCChan :: T.Text -> T.Text
sorryTunedOutOOCChan = sorryTunedOutChan "set"


sorryTunedOutPCSelf :: Sing -> T.Text
sorryTunedOutPCSelf s = "You have tuned out " <> s <> "."


sorryTunedOutPCTarget :: Sing -> T.Text
sorryTunedOutPCTarget s = s <> " has tuned you out."


-----


sorryTwoWayLink :: T.Text -> T.Text
sorryTwoWayLink t = "You haven't established a two-way telepathic link with anyone named " <> dblQuote t <> "."


sorryTwoWayTargetName :: ExpCmdName -> Sing -> T.Text
sorryTwoWayTargetName cn s = T.concat [ "In a telepathic message to "
                                      , s
                                      , ", the only possible target is "
                                      , s
                                      , ". Please try "
                                      , quoteColor
                                      , T.singleton expCmdChar
                                      , cn
                                      , " "
                                      , T.singleton . toLower . T.head $ s
                                      , dfltColor
                                      , " instead." ]


-----


sorryUnlinkIgnore :: T.Text
sorryUnlinkIgnore = sorryIgnoreLocPrefPlur "The names of the items to be removed from a container "


sorryUnlinkName :: T.Text -> T.Text
sorryUnlinkName t = T.concat [ "You don't have a link with "
                             , dblQuote t
                             , ". "
                             , parensQuote "Note that you must specify the full name of the person with whom you would \
                                           \like to unlink." ]


-----


sorryUnreadyCoins :: T.Text
sorryUnreadyCoins = "You can't unready coins."


sorryUnreadyInInv :: T.Text
sorryUnreadyInInv = "You can't unready items in your inventory."


sorryUnreadyInRm :: T.Text
sorryUnreadyInRm = "You can't unready items in your current room."


-----


sorryWrapLineLen :: T.Text
sorryWrapLineLen = T.concat [ "The line length must be between "
                            , showText minCols
                            , " and "
                            , showText maxCols
                            , " characters." ]


-----


sorryWtf :: T.Text
sorryWtf = quoteWith' (wtfColor, dfltColor) "He don't."