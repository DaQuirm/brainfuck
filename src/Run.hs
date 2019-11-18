module Run (
  run,
  RunArgs(..),
  runArgsParser
) where

import Prelude hiding       (interact)

import Data.Char            (ord)
import Data.Semigroup       ((<>))
import Options.Applicative
import Data.Word8           (Word8)
import Text.Parsec          (runP)
import Unsafe.Coerce        (unsafeCoerce)

import Interpreter          (ExecutionState(..), interpret, supplyInput)
import qualified Interpreter
import Lexer                (pBrainfuck)
import Optimizations        (optimize)

data RunArgs = RunArgs
    {
        file :: String
    }
    deriving (Show)

runArgsParser :: Parser RunArgs
runArgsParser = RunArgs
  <$> argument str (metavar "FILE" <> help "brainfuck source code")

run :: RunArgs -> IO ()
run (RunArgs filePath) = do
  instructions <- readFile filePath
  case (runP pBrainfuck 0 filePath instructions) of
      Left err    -> print err
      Right ops   -> interact $ Interpreter.init (optimize ops)

interact :: ExecutionState -> IO ()
interact (ProducedOutput state ops output)  = do
            putChar (word8ToChar output)
            interact $ interpret state ops
interact (WaitingForInput state ops)        = do
            input <- getChar
            interact $ supplyInput state ops (charToWord8 input)
interact (Finished _)                       = return ()

word8ToChar :: Word8 -> Char
word8ToChar = unsafeCoerce

charToWord8 :: Char -> Word8
charToWord8 char
    | ord char > 255    = 0
    | otherwise         = unsafeCoerce char

