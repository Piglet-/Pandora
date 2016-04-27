{-# LANGUAGE LambdaCase #-}

module Error
    ( Error(..)
    , isTokenError
    , LexerError(..)
    , module Lexeme
    ) where

import  Lexeme
import  Data.Function (on)

data Error
    = LError Position LexerError

instance Show Error where
    show = \case
        LError p e -> "Lexer error "   ++ show p ++ ":\n\t" ++ show e ++ "\n"
        
instance Eq Error where
    (==) = (==) `on` errorPos

--instance Ord Error where
--    compare = compare `on` errorPos

isTokenError :: Lexeme Token -> Bool
isTokenError (Lexeme (TokenError _) _)    = True
isTokenError (Lexeme (TokenIntError _) _) = True
isTokenError (Lexeme TokenBadComment _)   = True
isTokenError _                            = False

data LexerError
    = LexerError     String
    | UnexpectedChar Char
    | StringError    String
    | TokenNotSupported Token

instance Show LexerError where
    show = \case
        LexerError msg       -> msg
        UnexpectedChar c     -> "unexpected character '" ++ [c] ++ "'"
        StringError str      -> "missing matching quotation mark for string " ++ show str
        TokenNotSupported tk -> show tk ++ " is not supported yet"

errorPos :: Error -> Position
errorPos = \case
    LError p _ -> p