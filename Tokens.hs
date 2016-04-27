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
    | TokenVoid      | TokenArray     | TokenStringT

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
    | TokenFloatErrorO String
    | TokenFloatErrorU String
    | TokenEOF
    | TokenBadComment
    deriving (Eq)

-- show instance --
instance Show Token where
    show = \case
        TokenBracketOpen    -> "\nToken: BRACKET OPEN \nLexeme: [" 
        TokenBracketClose   -> "\nToken: BRACKET CLOSE\nLexeme: ]"
        TokenParenOpen      -> "\nToken: PARENT OPEN\nLexeme: ("
        TokenParenClose     -> "\nToken: PARENT CLOSE\nLexeme: )" 
        TokenComma          -> "\nToken: COMMA\nLexeme: ,"  
        TokenSemicolon      -> "\nToken: SEMICOLON\nLexeme: ;" 
        TokenPoint          -> "\nToken: POINT\nLexeme: ."
        TokenTwoPoints      -> "\nToken: TWOPOINTS\nLexeme: :"
        TokenIf             -> "\nToken: IF \nLexeme: if"
        TokenThen           -> "\nToken: THEN \nLexeme: then"
        TokenElse           -> "\nToken: ELSE \nLexeme: else"     
        TokenWhile          -> "\nToken: WHILE \nLexeme: while"   
        TokenFor            -> "\nToken: FOR \nLexeme: for"    
        TokenFrom           -> "\nToken: FROM \nLexeme: from"  
        TokenTo             -> "\nToken: TO \nLexeme: to" 
        TokenWith           -> "\nToken: WITH \nLexeme: with"
        TokenDo             -> "\nToken: DO \nLexeme: do"     
        TokenLike           -> "\nToken: LIKE \nLexeme: like"
        TokenHas            -> "\nToken: HAS \nLexeme: has"
        TokenReturn         -> "\nToken: RETURN \nLexeme: return"
        TokenNew            -> "\nToken: NEW \nLexeme: new"
        TokenBegin          -> "\nToken: BEGIN \nLexeme: begin"
        TokenEnd            -> "\nToken: END \nLexeme: end"
        TokenFunc           -> "\nToken: FUNC \nLexeme: func"
        TokenProc           -> "\nToken: PROC \nLexeme: proc"
        TokenFree           -> "\nToken: FREE \nLexeme: free"
        TokenRepeat         -> "\nToken: REPEAT \nLexeme: repeat" 
        TokenUntil          -> "\nToken: UNTIL \nLexeme: until"
        TokenRead           -> "\nToken: READ \nLexeme: read"
        TokenWrite          -> "\nToken: WRITE \nLexeme: write"
        TokenOf             -> "\nToken: OF \nLexeme: of"
        TokenITF            -> "\nToken: INTTOFLOAT \nLexeme: intToFloat"
        TokenITS            -> "\nToken: INTTOSTRING \nLexeme: intToString"
        TokenFTS            -> "\nToken: FLOATTOSTRING \nLexeme: floatToString"
        TokenIntT           -> "\nToken: TYPE INT \nLexeme: int"
        TokenBoolT          -> "\nToken: TYPE BOOL \nLexeme: bool"
        TokenFloatT         -> "\nToken: TYPE FLOAT \nLexeme: float"
        TokenCharT          -> "\nToken: TYPE CHAR \nLexeme: char"
        TokenStringT        -> "\nToken: TYPE STRING \nLexeme: string"
        TokenStruct         -> "\nToken: STRUCT \nLexeme: struct"
        TokenUnion          -> "\nToken: UNION \nLexeme: union"
        TokenVoid           -> "\nToken: VOID \nLexeme: void"
        TokenArray          -> "\nToken: ARRAY \nLexeme: array"
        TokenTrue           -> "\nToken: TRUE \nLexeme: true"
        TokenFalse          -> "\nToken: FALSE \nLexeme: false"
        TokenNull           -> "\nToken: NULL \nLexeme: null"
        TokenVar            -> "\nToken: VAR \nLexeme: var"
        TokenAssign         -> "\nToken: ASSIGN \nLexeme: ="
        TokenEq             -> "\nToken: EQUALITY \nLexeme: =="
        TokenIneq           -> "\nToken: INEQUALITY \nLexeme: /="
        TokenPlus           -> "\nToken: PLUS \nLexeme: +"
        TokenMinus          -> "\nToken: MINUS \nLexeme: -"
        TokenAsterisk       -> "\nToken: ASTERISK \nLexeme: *"
        TokenDivInt         -> "\nToken: DIV \nLexeme: div"
        TokenDivFloat       -> "\nToken: SLASH \nLexeme: /"
        TokenMod            -> "\nToken: MOD \nLexeme: mod"
        TokenGT             -> "\nToken: GREATHER THAN \nLexeme: >"
        TokenGE             -> "\nToken: GREATHER OR EQUAL \nLexeme: >="
        TokenLT             -> "\nToken: LESS THAN \nLexeme: <"
        TokenLE             -> "\nToken: LESS OR EQUAL \nLexeme: <="
        TokenCircum         -> "\nToken: POWER \nLexeme: ^"
        TokenAnd            -> "\nToken: AND \nLexeme: and"
        TokenOr             -> "\nToken: OR \nLexeme: or"
        TokenNot            -> "\nToken: NOT \nLexeme: not"
        TokenArrow          -> "\nToken: ARROW \nLexeme: ->"
        TokenInt      v     -> "\nToken: INTEGER \nValue: " ++ show v 
        TokenFloat    v     -> "\nToken: FLOAT \nValue: " ++ show v 
        TokenBool     v     -> "\nToken: BOOLEAN \nValue: " ++ show v
        TokenChar     v     -> "\nToken: CHAR \nValue: " ++ show v
        TokenString   v     -> "\nToken: STRING \nValue: " ++ show v
        TokenIdent    v     -> "\nToken: ID \nValue: " ++ v 
        TokenEOF            -> "\nEOF"
        TokenError    e     -> "\nUnexpected token: " ++ show e 
        TokenIntError e     -> "\nBad int error: " ++ show e ++ " (too large)"
        TokenFloatErrorO e  -> "\nBad float error: " ++ show e ++ " (overflow)"
        TokenFloatErrorU e  -> "\nBad float error: " ++ show e ++ " (underflow)"
        TokenBadComment     -> "\nComment not closed at end of file"