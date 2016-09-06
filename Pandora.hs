import Lexer
import Parser
import System.Environment (getArgs)
import SymbolTable
import Type
import Data.Either (lefts)
import qualified Data.Sequence as DS
--import Instructions
import qualified Data.Foldable as FB
import Control.Monad.RWS
import Data.Tree

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
                        else do let (state, bita) = execRWS (parse lexs) "" (State emptyZipper emptyZipper (AST []))
                                print $ defocus $ syt state
                                putStr "Strings Symbol Table:"
                                print $ defocus $ srt state
                                putStr $ drawTree (treeAST (filterI (ast state)))
                                putStr "\nErrors: \n"
                                putStr (filterBit bita)
                            --print $ drop 2 (show (parse lexs) ++ "Accepted") 
                else case head (tail args) of
                    "-l" -> if any isTokenError lexs 
                                then mapM_ fPrint (filter isTokenError lexs)
                                else mapM_ fPrint lexs
                    "-p" -> if any isTokenError lexs 
                                then mapM_ fPrint (filter isTokenError lexs)
                                else do let (state, bita) = execRWS (parse lexs) "" (State emptyZipper emptyZipper (AST []))
                                        print $ defocus $ syt state
                                        print $ defocus $ srt state
                                        putStr (filterBit bita)
                                    --print $ drop 2 (show (parse lexs) ++ "Accepted") 
                    _    -> print help
        Left error -> print error

help :: String
help = "Los flags permitidos por ahora son -l (lexer) y -p (parser)"

emptyZipper :: Zipper
emptyZipper = focus $ emptyST emptyScope

filterBit :: DS.Seq(Binnacle) -> String
filterBit bs = unlines (lefts (FB.toList bs))
--    case scanner str of
        --Right lexs -> mapM_ fPrint lexs
--        Right lexs -> print (parse lexs)   
        --Left error -> print error
