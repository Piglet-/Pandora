import Lexer
import Parser
import System.Environment (getArgs)

main = do
    args <- getArgs
    str <- if null args
        then getContents
        else readFile (head args)
    case scanner str of
        Right lexs -> mapM_ fPrint lexs
        Left error -> print error