import Lexer
import Parser
import System.Environment (getArgs)
import SymbolTable
import Control.Monad.RWS

main = do
    args <- getArgs
    str <- if null args
        then getContents
        else readFile (head args)
    case scanner str of
        Right lexs ->
            if null (tail args)
                then if any isTokenError lexs 
                        then mapM_ fPrint (filter isTokenError lexs)
                        else do let (state, bita) = execRWS (parse lexs) "" (focus $ emptyST emptyScope, focus $ emptyST emptyScope )
                                print $ defocus $ fst state
                            --print $ drop 2 (show (parse lexs) ++ "Accepted") 
                else case head (tail args) of
                    "-l" -> if any isTokenError lexs 
                                then mapM_ fPrint (filter isTokenError lexs)
                                else mapM_ fPrint lexs
                    "-p" -> if any isTokenError lexs 
                                then mapM_ fPrint (filter isTokenError lexs)
                                else do let (state, bita) = execRWS (parse lexs) "" (focus $ emptyST emptyScope, focus $ emptyST emptyScope )
                                        print $ defocus $ fst state
                                    --print $ drop 2 (show (parse lexs) ++ "Accepted") 
                    _    -> print help
        Left error -> print error

help :: String
help = "Los flags permitidos por ahora son -l (lexer) y -p (parser)"

--    case scanner str of
        --Right lexs -> mapM_ fPrint lexs
--        Right lexs -> print (parse lexs)   
        --Left error -> print error