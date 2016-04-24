module Tokens
( Pos(..)
, Token(..)
, isTokenError
, printError
, tp
) where

-- token's position --
data Pos = Pos Int Int 
        deriving Eq

-- show instance --        
instance Show Pos where
    show (Pos l c) = "(Line: " ++ show l ++ ", Column: " ++ show c ++ ")"

-- tokens of Pandora --
data Token
    -- punctuation --
    -- brackets --
    = TokenBracketOpen Pos  | TokenBracketClose Pos
    | TokenParenOpen Pos    | TokenParenClose Pos

    -- separators --
    | TokenComma Pos | TokenSemicolon Pos

    -- access to fields --
    | TokenPoint Pos

    -- type declarations --
    | TokenTwoPoints Pos

    -- instructions --
    | TokenIf Pos       | TokenThen Pos     | TokenElse Pos     
    | TokenWhile Pos    | TokenFor Pos      | TokenFrom  Pos 
    | TokenTo Pos       | TokenWith Pos     | TokenDo Pos     
    | TokenLike Pos     | TokenHas Pos      | TokenReturn Pos
    | TokenNew Pos      | TokenBegin Pos    | TokenEnd Pos      
    | TokenFunc Pos     | TokenProc Pos     | TokenFree Pos
    | TokenRepeat Pos   | TokenUntil Pos    | TokenRead Pos     
    | TokenWrite Pos    | TokenOf Pos

    -- types --
    | TokenIntT Pos     | TokenBool Pos     | TokenFloat Pos
    | TokenChar Pos     | TokenStruct Pos   | TokenUnion Pos
    | TokenVoid Pos     | TokenArray Pos

    -- boolean constants --
    | TokenTrue Pos | TokenFalse Pos

    -- null value --
    | TokenNull Pos

   -- reference id --
   | TokenVar Pos

    -- operators --
    -- binary --
    | TokenAssign Pos   | TokenEq Pos       | TokenIneq Pos
    | TokenPlus Pos     | TokenMinus Pos    | TokenAsterisk Pos
    | TokenDivInt Pos   | TokenDivFloat Pos | TokenMod Pos
    | TokenGT Pos       | TokenGE Pos       | TokenLT Pos 
    | TokenLE Pos       | TokenCircum Pos   | TokenAnd Pos
    | TokenOr Pos       

    -- unary --
    | TokenNot Pos | TokenArrow Pos 

    -- variables --
    | TokenInt    Int    Pos
    | TokenString String Pos
    | TokenIdent  String Pos

    -- errors --
    | TokenError    String Pos
    | TokenIntError String Pos
    | TokenEOF Pos
    deriving Eq

-- show instance --
-- instance Show Token where

-- TokenPosition function --
tp :: Token -> Pos
tp t = case t of
    -- punctuation --
     -- brackets --
    (TokenBracketOpen p)  -> p
    (TokenBracketClose p) -> p
    (TokenParenOpen p)  -> p
    (TokenParenClose p) -> p

    -- separators --
    (TokenComma p)      -> p
    (TokenSemicolon p)  -> p

    -- access to fields --
    (TokenPoint p) -> p

    -- type declarations --
    (TokenTwoPoints p) -> p

    -- instructions --
    (TokenIf p)     -> p
    (TokenThen p)   -> p
    (TokenElse p)   -> p     
    (TokenWhile p)  -> p
    (TokenFor p)    -> p 
    (TokenFrom p)   -> p
    (TokenTo p)     -> p
    (TokenWith p)   -> p 
    (TokenDo p)     -> p     
    (TokenLike p)   -> p
    (TokenHas p)    -> p 
    (TokenReturn p) -> p
    (TokenNew p)    -> p 
    (TokenBegin p)  -> p
    (TokenEnd p)    -> p      
    (TokenFunc p)   -> p  
    (TokenProc p)   -> p
    (TokenFree p)   -> p
    (TokenRepeat p) -> p 
    (TokenUntil p)  -> p  
    (TokenRead p)   -> p     
    (TokenWrite p)  -> p   
    (TokenOf p)     -> p

    -- types --
    (TokenIntT p)   -> p     
    (TokenBool p)   -> p   
    (TokenFloat p)  -> p
    (TokenChar p)   -> p    
    (TokenStruct p) -> p   
    (TokenUnion p)  -> p
    (TokenVoid p)   -> p     
    (TokenArray p)  -> p

    -- boolean constants --
    (TokenTrue p)   -> p 
    (TokenFalse p)  -> p

    -- null value --
    (TokenNull p) -> p

   -- reference id --
    (TokenVar p) -> p

   -- operators --
    -- binary --
    (TokenAssign p)     -> p   
    (TokenEq p)         -> p       
    (TokenIneq p)       -> p
    (TokenPlus p)       -> p     
    (TokenMinus p)      -> p    
    (TokenAsterisk p)   -> p
    (TokenDivInt p)     -> p   
    (TokenDivFloat p)   -> p 
    (TokenMod p)        -> p
    (TokenGT p)         -> p       
    (TokenGE p)         -> p       
    (TokenLT p)         -> p 
    (TokenLE p)         -> p       
    (TokenCircum p)     -> p   
    (TokenAnd p)        -> p
    (TokenOr p)         -> p       

    -- unary --
    (TokenNot p)    -> p 
    (TokenArrow p)  -> p

    -- variables --
    (TokenInt _ p)      -> p
    (TokenString _ p)   -> p
    (TokenIdent  _ p)   -> p

    -- errors --
    (TokenError _ p)    -> p
    (TokenIntError _ p) -> p
    (TokenEOF p)        -> p


printError :: Token -> IO ()
printError (TokenError s p) = do
  putStrLn $ "Error: unexpected token \"" ++ s ++ "\" " ++ show p
printError (TokenIntError s p) = do
  putStrLn $ "Error: integer out of range (-2^31 .. 2^31-1) \"" ++ s ++
    "\" " ++ show p

isTokenError :: Token -> Bool
isTokenError (TokenError    _ _) = True
isTokenError (TokenIntError _ _) = True
isTokenError _                   = False