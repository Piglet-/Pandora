{-# LANGUAGE LambdaCase #-}

module Tokens
( Token(..)
) where

-- tokens of Pandora --
data Token
    -- punctuation --
    -- brackets --
    = TokenBracketOpen   | TokenBracketClose 
    | TokenParenOpen     | TokenParenClose 

    -- separators --
    | TokenComma  | TokenSemicolon 

    -- access to fields --
    | TokenPoint 

    -- type declarations --
    | TokenTwoPoints 

    -- instructions --
    | TokenIf        | TokenThen      | TokenElse      
    | TokenWhile     | TokenFor       | TokenFrom   
    | TokenTo        | TokenWith      | TokenDo      
    | TokenLike      | TokenHas       | TokenReturn 
    | TokenNew       | TokenBegin     | TokenEnd       
    | TokenFunc      | TokenProc      | TokenFree 
    | TokenRepeat    | TokenUntil     | TokenRead      
    | TokenWrite     | TokenOf        | TokenITS
    | TokenFTS       | TokenITF

    -- types --
    | TokenIntT      | TokenBoolT     | TokenFloatT 
    | TokenCharT     | TokenStruct    | TokenUnion 
    | TokenVoid      | TokenArray 

    -- boolean constants --
    | TokenTrue  | TokenFalse 

    -- null value --
    | TokenNull 

   -- reference id --
   | TokenVar 

    -- operators --
    -- binary --
    | TokenAssign    | TokenEq        | TokenIneq 
    | TokenPlus      | TokenMinus     | TokenAsterisk 
    | TokenDivInt    | TokenDivFloat  | TokenMod 
    | TokenGT        | TokenGE        | TokenLT  
    | TokenLE        | TokenCircum    | TokenAnd 
    | TokenOr       

    -- unary --
    | TokenNot  | TokenArrow  

    -- variables --
    | TokenInt      Int   
    | TokenFloat    Float 
    | TokenBool     Bool
    | TokenChar     Char 
    | TokenString   String 
    | TokenIdent    String 

    -- errors --
    | TokenError    Char 
    | TokenIntError String 
    | TokenFloatError String
    | TokenEOF
    | TokenBadComment
    deriving (Eq)

-- show instance --
instance Show Token where
    show = \case
        TokenBracketOpen    -> "[" 
        TokenBracketClose   -> "]"
        TokenParenOpen      -> "("
        TokenParenClose     -> ")" 
        TokenComma          -> ","  
        TokenSemicolon      -> ";" 
        TokenPoint          -> "."
        TokenTwoPoints      -> ":"
        TokenIf             -> "IF"
        TokenThen           -> "THEN"
        TokenElse           -> "ELSE"     
        TokenWhile          -> "WHILE"   
        TokenFor            -> "FOR"    
        TokenFrom           -> "FROM"  
        TokenTo             -> "TO" 
        TokenWith           -> "WITH"
        TokenDo             -> "DO"     
        TokenLike           -> "LIKE"
        TokenHas            -> "HAS"
        TokenReturn         -> "RETURN"
        TokenNew            -> "NEW"
        TokenBegin          -> "BEGIN"
        TokenEnd            -> "END"
        TokenFunc           -> "FUNC"
        TokenProc           -> "PROC"
        TokenFree           -> "FREE"
        TokenRepeat         -> "REPEAT" 
        TokenUntil          -> "UNTIL"
        TokenRead           -> "READ"
        TokenWrite          -> "WRITE"
        TokenOf             -> "OF"
        TokenITF            -> "INTTOFLOAT"
        TokenITS            -> "INTTOSTRING"
        TokenFTS            -> "FLOATTOSTRING"
        TokenIntT           -> "INT"
        TokenBoolT          -> "BOOL"
        TokenFloatT         -> "FLOAT"
        TokenCharT          -> "CHAR"
        TokenStruct         -> "STRUCT"
        TokenUnion          -> "UNION"
        TokenVoid           -> "VOID"
        TokenArray          -> "ARRAY"
        TokenTrue           -> "TRUE"
        TokenFalse          -> "FALSE"
        TokenNull           -> "NULL"
        TokenVar            -> "VAR"
        TokenAssign         -> "ASSIGN"
        TokenEq             -> "=="
        TokenIneq           -> "/="
        TokenPlus           -> "+"
        TokenMinus          -> "-"
        TokenAsterisk       -> "*"
        TokenDivInt         -> "DIV"
        TokenDivFloat       -> "/"
        TokenMod            -> "MOD"
        TokenGT             -> ">"
        TokenGE             -> ">="
        TokenLT             -> "<"
        TokenLE             -> "<="
        TokenCircum         -> "^"
        TokenAnd            -> "AND"
        TokenOr             -> "OR"
        TokenNot            -> "NOT"
        TokenArrow          -> "->"
        TokenInt      v     -> show v 
        TokenFloat    v     -> show v 
        TokenBool     v     -> show v
        TokenChar     v     -> show v
        TokenString   v     -> show v
        TokenIdent    v     -> show v 
        TokenEOF            -> "EOF"
        TokenError    e     -> show e 
        TokenIntError e     -> "Error" ++ show e
        TokenFloatError e   -> show e 
        TokenBadComment     -> "Comment not closed at end of file"