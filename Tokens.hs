{-# LANGUAGE LambdaCase #-}

---------------------- Módulo que representa los tokens -----------------------
module Tokens
( Token(..)
) where

-- tipo de datos para los tokens del lenguaje --
data Token
 -------------------------- puntuación ---------------------------------
    -- corchetes
    = TokenBracketOpen   | TokenBracketClose 
    | TokenParenOpen     | TokenParenClose 

    -- separadores --
    | TokenComma  | TokenSemicolon 

    -- acceso a campos --
    | TokenPoint 

    -- declaración de tipos --
    | TokenColon

------------------------ instrucciones ---------------------------------
    | TokenIf        | TokenThen      | TokenElse      
    | TokenWhile     | TokenFor       | TokenFrom   
    | TokenTo        | TokenWith      | TokenDo      
    | TokenLike      | TokenHas       | TokenReturn 
    | TokenNew       | TokenBegin     | TokenEnd       
    | TokenFunc      | TokenProc      | TokenFree 
    | TokenRepeat    | TokenUntil     | TokenRead      
    | TokenWrite     | TokenOf        | TokenITS
    | TokenFTS       | TokenITF

    -- tipos --
    | TokenIntT      | TokenBoolT     | TokenFloatT 
    | TokenCharT     | TokenStruct    | TokenUnion 
    | TokenVoid      | TokenArray     | TokenStringT

    -- constantes booleanas --
    | TokenTrue  | TokenFalse 

    -- null --
    | TokenNull 

   -- valor por referencia --
   | TokenVar 

-------------------------- operatdores ---------------------------------
    -- binarios --
    | TokenAssign    | TokenEq        | TokenIneq 
    | TokenPlus      | TokenMinus     | TokenAsterisk 
    | TokenDivInt    | TokenDivFloat  | TokenMod 
    | TokenGT        | TokenGE        | TokenLT  
    | TokenLE        | TokenCircum    | TokenAnd 
    | TokenOr       

    -- unarios --
    | TokenNot  | TokenArrow  

---------------------------- variables ---------------------------------
    | TokenInt      Int   
    | TokenFloat    Float 
    | TokenChar     Char 
    | TokenString   String 
    | TokenIdent    String 

---------------------------- errores -----------------------------------
    | TokenError        Char 
    | TokenIntError     String 
    | TokenFloatErrorO  String
    | TokenFloatErrorU  String
    | TokenEOF
    | TokenStringError  
    | TokenBadComment
    deriving (Eq)

-- instancia show que muestra detalles de los tokens --
instance Show Token where
    show = \case
        TokenBracketOpen    -> "\nToken: BRACKET OPEN \nLexeme: [" 
        TokenBracketClose   -> "\nToken: BRACKET CLOSE\nLexeme: ]"
        TokenParenOpen      -> "\nToken: PARENT OPEN\nLexeme: ("
        TokenParenClose     -> "\nToken: PARENT CLOSE\nLexeme: )" 
        TokenComma          -> "\nToken: COMMA\nLexeme: ,"  
        TokenSemicolon      -> "\nToken: SEMICOLON\nLexeme: ;" 
        TokenPoint          -> "\nToken: POINT\nLexeme: ."
        TokenColon          -> "\nToken: COLON\nLexeme: :"
        TokenIf             -> "\nToken: IF"
        TokenThen           -> "\nToken: THEN"
        TokenElse           -> "\nToken: ELSE"     
        TokenWhile          -> "\nToken: WHILE"   
        TokenFor            -> "\nToken: FOR"    
        TokenFrom           -> "\nToken: FROM"  
        TokenTo             -> "\nToken: TO" 
        TokenWith           -> "\nToken: WITH"
        TokenDo             -> "\nToken: DO"     
        TokenLike           -> "\nToken: LIKE"
        TokenHas            -> "\nToken: HAS"
        TokenReturn         -> "\nToken: RETURN"
        TokenNew            -> "\nToken: NEW"
        TokenBegin          -> "\nToken: BEGIN"
        TokenEnd            -> "\nToken: END"
        TokenFunc           -> "\nToken: FUNC"
        TokenProc           -> "\nToken: PROC"
        TokenFree           -> "\nToken: FREE"
        TokenRepeat         -> "\nToken: REPEAT" 
        TokenUntil          -> "\nToken: UNTIL"
        TokenRead           -> "\nToken: READ"
        TokenWrite          -> "\nToken: WRITE"
        TokenOf             -> "\nToken: OF"
        TokenITF            -> "\nToken: INTTOFLOAT"
        TokenITS            -> "\nToken: INTTOSTRING"
        TokenFTS            -> "\nToken: FLOATTOSTRING"
        TokenIntT           -> "\nToken: INT"
        TokenBoolT          -> "\nToken: BOOL"
        TokenFloatT         -> "\nToken: FLOAT"
        TokenCharT          -> "\nToken: CHAR"
        TokenStringT        -> "\nToken: STRING"
        TokenStruct         -> "\nToken: STRUCT"
        TokenUnion          -> "\nToken: UNION"
        TokenVoid           -> "\nToken: VOID"
        TokenArray          -> "\nToken: ARRAY"
        TokenTrue           -> "\nToken: TRUE"
        TokenFalse          -> "\nToken: FALSE"
        TokenNull           -> "\nToken: NULL"
        TokenVar            -> "\nToken: VARr"
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
        TokenChar     v     -> "\nToken: CHAR \nValue: " ++ show v
        TokenString   v     -> "\nToken: STRING \nValue: " ++ v
        TokenIdent    v     -> "\nToken: ID \nValue: " ++ v 
        TokenEOF            -> "\nEOF"
        TokenError    e     -> "\nUnexpected token: " ++ show e 
        TokenIntError e     -> "\nBad int error: " ++ show e ++ " (too large)"
        TokenFloatErrorO e  -> "\nBad float error: " ++ show e ++ " (overflow)"
        TokenFloatErrorU e  -> "\nBad float error: " ++ show e ++ " (underflow)"
        TokenBadComment     -> "\nComment not closed at end of file"
        TokenStringError    -> "\nString not closed (missing character '\"' at end of line)"   