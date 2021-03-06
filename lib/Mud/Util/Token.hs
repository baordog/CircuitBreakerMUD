{-# LANGUAGE OverloadedStrings, ViewPatterns #-}

module Mud.Util.Token (parseTokens) where

import Mud.Cmds.Msgs.Misc
import Mud.Misc.ANSI
import Mud.TopLvlDefs.Chars
import Mud.TopLvlDefs.Misc
import Mud.Util.Misc hiding (patternMatchFail)
import Mud.Util.Text
import qualified Mud.Util.Misc as U (patternMatchFail)

import Data.Char (toLower)
import Data.Monoid ((<>))
import Data.Text (Text)
import qualified Data.Text as T


patternMatchFail :: (Show a) => PatternMatchFail a b
patternMatchFail = U.patternMatchFail "Mud.Util.Token"


-- ==================================================


parseTokens :: Text -> Text
parseTokens = parseCharTokens . parseStyleTokens . parseMiscTokens


-----


type Delimiter = Char


parser :: (Char -> Text) -> Delimiter -> Text -> Text
parser f d t
  | T.singleton d `notInfixOf` t = t
  | (left, headTail . T.tail -> (c, right)) <- T.breakOn (T.singleton d) t = left <> f c <> parser f d right


-----


parseCharTokens :: Text -> Text
parseCharTokens = parser expandCharCode charTokenDelimiter


expandCharCode :: Char -> Text
expandCharCode c | c == charTokenDelimiter = T.singleton charTokenDelimiter
expandCharCode (toLower -> code)           = T.singleton $ case code of
  'a' -> allChar
  'b' -> debugCmdChar
  'c' -> adverbCloseChar
  'd' -> adminCmdChar
  'e' -> emoteNameChar
  'h' -> chanTargetChar
  'i' -> indexChar
  'k' -> miscTokenDelimiter
  'l' -> selectorChar
  'm' -> amountChar
  'n' -> leadingSpaceChar
  'o' -> adverbOpenChar
  'p' -> expCmdChar
  'q' -> quoteChar
  'r' -> emoteTargetChar
  's' -> slotChar
  't' -> sayToChar
  'u' -> multiLineEndChar
  'x' -> emoteChar
  x   -> patternMatchFail "expandCharCode" . T.singleton $ x


-----


parseMiscTokens :: Text -> Text
parseMiscTokens = twice (parser expandMiscCode miscTokenDelimiter)


expandMiscCode :: Char -> Text
expandMiscCode (toLower -> code) = case code of
  'b' -> dfltBootMsg
  'c' -> descRule5
  'd' -> yesNo isDebug
  'e' -> descRulesMsg
  'p' -> pwWarningMsg
  'r' -> rulesIntroMsg
  's' -> dfltShutdownMsg
  'u' -> rulesMsg
  'v' -> violationMsg
  'z' -> yesNo $ isDebug && isZBackDoor
  x   -> patternMatchFail "expandMiscCode" . T.singleton $ x


-----


parseStyleTokens :: Text -> Text
parseStyleTokens = parser expandStyleCode styleTokenDelimiter


expandStyleCode :: Char -> Text
expandStyleCode c | c == styleTokenDelimiter = T.singleton styleTokenDelimiter
expandStyleCode (toLower -> code)            = case code of
  'a' -> abbrevColor
  'd' -> dfltColor
  'e' -> emphasisColor
  'h' -> headerColor
  'i' -> asteriskColor
  'k' -> knownNameColor
  'l' -> selectorColor
  'm' -> tempDescColor
  'n' -> noUnderlineANSI
  'o' -> unknownNameColor
  'p' -> prefixColor
  'q' -> quoteColor
  'r' -> arrowColor
  's' -> syntaxSymbolColor
  't' -> toNpcColor
  'u' -> underlineANSI
  'z' -> zingColor
  x   -> patternMatchFail "expandStyleCode" . T.singleton $ x
