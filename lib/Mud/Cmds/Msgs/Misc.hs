{-# LANGUAGE OverloadedStrings #-}

module Mud.Cmds.Msgs.Misc where

import Mud.Data.State.MudData
import Mud.TopLvlDefs.Chars
import Mud.TopLvlDefs.Misc
import Mud.Util.Quoting
import Mud.Util.Text

import Data.Monoid ((<>))
import Data.Text (Text)
import qualified Data.Text as T


asMsg :: Text
asMsg = "You suddenly feel as though someone else is in control..."


bannedMsg :: Text
bannedMsg = "You have been banned from CurryMUD!"


blankWritableMsg :: Sing -> Text
blankWritableMsg s = prd $ "There isn't anything written on the " <> s


dbEmptyMsg :: Text
dbEmptyMsg = "The database is empty."


dbErrorMsg :: Text
dbErrorMsg = "There was an error while reading the database."


descRulesMsg :: Text
descRulesMsg =
    "1) Descriptions must be realistic and reasonable. A felinoid with an unusual fur color is acceptable, while a \
    \six-foot dwarf is not.3`\n\
    \2) Descriptions must be passive and written from an objective viewpoint. \"He is exceptionally thin\" is \
    \acceptable, while \"You can't believe how thin he is\" is not.3`\n\
    \3) Descriptions may only contain observable information. \"People tend to ask her about her adventures\" and \"He \
    \is a true visionary among elves\" are both illegal. Likewise, you may not include your character's name in your \
    \name in your description.3`\n\
    \4) Keep your description short. The longer your description, the less likely people are to actually read it!3`"


descRule5 :: Text
descRule5 =
    "5) You may not make radical changes to your description without a plausible in-game explanation. This means that \
    \it is normally illegal to make sudden, striking changes to enduring physical characteristics (height, eye color, \
    \etc.). If you would like to make such a change and feel there could be a plausible in-game explanation, get \
    \permission from an administrator first.3`"


dfltBootMsg :: Text
dfltBootMsg = "You have been booted from CurryMUD. Goodbye!"


dfltShutdownMsg :: Text
dfltShutdownMsg = "CurryMUD is shutting down. We apologize for the inconvenience. See you soon!"


effortsBlockedMsg :: Text
effortsBlockedMsg = "Your efforts are blocked; "


egressMsg :: Text -> Text
egressMsg n = n <> " slowly dissolves into nothingness."


enterDescMsgs :: [Text]
enterDescMsgs =
    [ "Enter your new description below. You may write multiple lines of text; however, multiple lines will be joined \
      \into a single line which, when displayed, will be wrapped according to one's columns setting."
    , "You are encouraged to compose your description in an external text editor "
    , parensQuote "such as TextEdit on Mac, and gedit or kate on Linux systems" <>
      ", with spell checking enabled. Copy your completed description from there and paste it into your MUD client."
    , "When you are finished, enter a " <> endCharTxt <> " on a new line." ]
  where
    endCharTxt = dblQuote . T.singleton $ multiLineEndChar


focusingInnateMsg :: Text
focusingInnateMsg = "Focusing your innate psionic energy for a brief moment, "


genericErrorMsg :: Text
genericErrorMsg = "Unfortunately, an error occured while executing your command."


helloRulesMsg :: Text
helloRulesMsg = "*** By logging in you are expressing a commitment to follow the rules. ***"


helpRootErrorMsg :: Text
helpRootErrorMsg = helpFileErrorMsg "root"


helpFileErrorMsg :: Text -> Text
helpFileErrorMsg n = "Unfortunately, the " <> n <> " help file could not be read."


inacBootMsg :: Text
inacBootMsg = "You are being disconnected from CurryMUD due to inactivity."


loadTblErrorMsg :: FilePath -> Text -> Text
loadTblErrorMsg fp msg = T.concat [ "error parsing ", dblQuote . T.pack $ fp, ": ", msg, "." ]


loadWorldErrorMsg :: Text
loadWorldErrorMsg = "There was an error loading the world. Check the error log for details."


lvlUpMsg :: Text
lvlUpMsg = "Congratulations! You gained a level."


motdErrorMsg :: Text
motdErrorMsg = "Unfortunately, the message of the day could not be retrieved."


noSmellMsg :: Text
noSmellMsg = "You don't smell anything in particular."


noSoundMsg :: Text
noSoundMsg = "You don't hear anything in particular."


noTasteMsg :: Text
noTasteMsg = "You don't taste anything in particular."


notifyArrivalMsg :: Text -> Text
notifyArrivalMsg n = n <> " slowly materializes out of thin air."


plusRelatedMsg :: Text
plusRelatedMsg = prd . parensQuote $ "plus related functionality"


pwMsg :: Text -> [Text]
pwMsg t = [ T.concat [ t
                     , " Passwords must be "
                     , showText minPwLen
                     , "-"
                     , showText maxPwLen
                     , " characters in length and contain:" ]
          , "* 1 or more lowercase characters"
          , "* 1 or more uppercase characters"
          , "* 1 or more digits"
          , "* 0 whitespace characters" ]


pwWarningMsg :: Text
pwWarningMsg = pwWarningTxt <> ".)"


pwWarningLoginMsg :: Text
pwWarningLoginMsg = pwWarningTxt <> " once inside the game.)"


pwWarningTxt :: Text
pwWarningTxt = "Please make a note of your new password. If you lose your password, you may lose your character! \
               \(To safeguard against this unfortunate situation, use the " <> dblQuote "security" <> " command to \
               \provide a security Q&A"


rethrowExMsg :: Text -> Text
rethrowExMsg t = "exception caught " <> t <> "; rethrowing to listen thread"


rulesIntroMsg :: Text
rulesIntroMsg = "In order to preserve the integrity of the virtual world along with the enjoyment of all, the \
                \following rules must be observed."


rulesMsg :: Text
rulesMsg =
    "\\h RULES \\d\n\
    \\n" <>
    spcs <> "You must conduct yourself in accordance with the following rules. It is not the case that you are allowed to do whatever the virtual world lets you do: please understand this important point.\n" <>
    spcs <> T.singleton miscTokenDelimiter <> "v\n\
    \\n\
    \\\uAGE\\d\n" <>
    spcs <> "CurryMUD a complex game that requires serious, consistent role-play and adult sensibilities. For these reasons you must be at least 18 years old to play.\n\
    \\n\
    \\\uROLE-PLAY\\d\n" <>
    spcs <> "CurryMUD is a Role-Play Intensive (RPI) MUD. You are required to devise a unique personality for your character and to stay In Character (IC) at all times. IC communication must always be appropriate for the fantasy context of the virtual world; references to the present day/reality are not allowed.\n" <>
    spcs <> "There are a few exceptions to this rule. The \"question channel\" (for asking and answering newbie questions related to game play) is Out-Of-Character (OOC). Certain areas within the virtual world are also clearly designated as OOC: you are allowed to communicate with other players as a player (as yourself) within such areas.\n\
    \\n\
    \\\uILLEGAL ROLE-PLAY\\d\n" <>
    spcs <> "You are not allowed to role-play a character who is insane, sadistic, or sociopathic.\n\
    \\n\
    \\\uRESPECT\\d\n" <>
    spcs <> "You must conduct yourself in a manner that is empathetic towards your fellow players. Be respectful and sensible; don't be rude or condescending.\n\
    \\n\
    \\\uHARASSMENT\\d\n" <>
    spcs <> "Harassment and bullying will not be tolerated. The role-play of rape is absolutely illegal.\n\
    \\n\
    \\\uSEXUAL ORIENTATION/IDENTITY\\d\n" <>
    spcs <> "Players are free to role-play characters who are homosexual, bisexual, pansexual, gender nonconforming, etc. Intolerant attitudes are unacceptable.\n\
    \\n\
    \\\uPERMADEATH\\d\n" <>
    spcs <> "This means that when a character dies, he/she is truly dead; a deceased character cannot return to the virtual world in any way, shape, or form. By playing CurryMUD, you consent to the fact that when your character dies, he/she is unrecoverable.\n\
    \\n\
    \\\uPLAYER-VS-PLAYER\\d\n\
    \TODO\n\
    \\n\
    \\\uMULTI-PLAYING\\d\n" <>
    spcs <> "\"Multi-playing\" is when a single player simultaneously logs in multiple times, as multiple characters. This is not allowed.\n" <>
    spcs <> "It is likewise illegal to transfer items and wealth between characters through indirect means (for example, dropping items in a certain location, logging in as a different character, and picking up those items).\n" <>
    spcs <> "You are discouraged from actively maintaining multiple characters at a time. It can be quite difficult to juggle the different scopes of knowledge - and to maintain the disparate levels of objectivity - inherent in multiple characters. If you find yourself wanting to play a new character, consider formally retiring your current character via the \"retire\" command.\n\
    \\n\
    \\\uBUGS\\d\n" <>
    spcs <> "The abuse of bugs constitutes cheating and is not allowed. If you find a bug, you must promptly report it via the \"bug\" command, or inform an administrator directly via the \"admin\" command.\n\
    \\n\
    \\\uPRIVACY\\d\n" <>
    spcs <> "Please be aware that player activity is automatically logged by the system. Furthermore, administrators have the ability to actively monitor player activity with the express purpose of 1) ensuring that players are playing by the rules, and 2) tracking down bugs. Administrators promise to maintain player privacy as much as possible."
  where
    spcs = T.replicate 2 . T.pack $ charTokenDelimiter : "n"


sudoMsg :: Text
sudoMsg = "HELLO, ROOT! We trust you have received the usual lecture from the local System Administrator..."


teleDescMsg :: Text
teleDescMsg = "You are instantly transported in a blinding flash of white light. For a brief moment you are \
              \overwhelmed with vertigo accompanied by a confusing sensation of nostalgia."


teleDestMsg :: Text -> Text
teleDestMsg t = "There is a soft audible pop as " <> t <> " appears in a jarring flash of white light."


teleOriginMsg :: Text -> Text
teleOriginMsg t = "There is a soft audible pop as " <> t <> " vanishes in a jarring flash of white light."


unlinkMsg :: Text -> Sing -> Text
unlinkMsg t s = T.concat [ "You suddenly feel a slight tingle "
                         , t
                         , "; you sense that your telepathic link with "
                         , s
                         , " has been severed." ]

violationMsg :: Text
violationMsg = "Violation of these rules is grounds for discipline up to and including banishment from CurryMUD."
