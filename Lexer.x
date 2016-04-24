{
module Lexer
    ( Alex(..)
    , Token(..)
    , Lexeme(..)
    , Error(..)
    ) where

import Tokens
import Error
import Lexeme
import Control.Monad
import Data.Sequence (Seq, (|>), empty)
}

%wrapper "monadUserState"

$digit = 0-9
$lower = [a-z _]
$upper = [A-Z]
@ident = $lower($upper|$lower|digit)*

tokens :- 

    --Whitespaces
    <0> $white+ ;

    --Comment
    <0> "--".*  ;
    --Nested Comment
    <0> "-*"    { enterNewComment `andBegin` n}
    <n> "-*"    { embedComment }
    <n> "*-"    { unembedComment }
    <n> .       ;
    <n> \n      { skip }

    -- Identifier
    <0> @ident  { tok TokenIdent }

{
    
data AlexUserState = 
    AlexUST 
        { errors            :: Seq Error
        , lexerCommentDepth :: Int 
        }

alexInitUserState :: AlexUserState
alexInitUserState = 
    AlexUST
        { errors = empty
        , lexerCommentDepth = 0
        } 

getLexerCommentDepth :: Alex Int
getLexerCommentDepth = 
    Alex $ \s@AlexState{alex_ust=ust} -> Right (s, lexerCommentDepth ust)

setLexerCommentDepth :: Int -> Alex ()
setLexerCommentDepth ss = 
    Alex $ \s -> Right (s{alex_ust=(alex_ust s){lexerCommentDepth=ss}}, ())

toPosition :: AlexPosn -> Position
toPosition (AlexPn _ r c) = Position (r, c)

alexEOF :: Alex (Lexeme Token )
alexEOF = liftM (Lexeme TokenEOF ) alexGetPosition

tok :: (String -> Token) -> AlexAction ( Lexeme Token )
tok f (p,_,_,s) i = return $ Lexeme (f $ take i s) (toPosition p)

alexGetPosition :: Alex Position
alexGetPosition = alexGetInput >>= \(p,_,_,_) -> return $ toPosition p

enterNewComment input len =
    do setLexerCommentDepth 1
       skip input len

embedComment input len =
    do cd <- getLexerCommentDepth
       setLexerCommentDepth (cd + 1)
       skip input len

unembedComment input len =
    do cd <- getLexerCommentDepth
       setLexerCommentDepth (cd - 1)
       when (cd == 1) (alexSetStartCode state_initial)
       skip input len


state_initial :: Int
state_initial = 0




}






