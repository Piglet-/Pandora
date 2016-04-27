{-# LANGUAGE LambdaCase #-}

------------- Módulo que representa los errores lexicográficos ----------------
module Error
    ( Error(..)
    , isTokenError
    , LexerError(..)
    , module Lexeme
    ) where

import  Lexeme
import  Data.Function (on)

-- tipo de datos que representa los errores y contienen su posición
data Error
    = LError Position LexerError

-- instancia show que muestra la información de un error
instance Show Error where
    show = \case
        LError p e -> "Lexer error "   ++ show p ++ ":\n\t" ++ show e ++ "\n"
        
instance Eq Error where
    (==) = (==) `on` errorPos

-- función que determina si un token es un error lexicográfico
isTokenError :: Lexeme Token -> Bool
isTokenError (Lexeme (TokenError _) _)    = True
isTokenError (Lexeme (TokenIntError _) _) = True
isTokenError (Lexeme TokenBadComment _)   = True
isTokenError _                            = False

-- tipo de dato para los errores de lexer
data LexerError
    = LexerError     String
    | UnexpectedChar Char
    | StringError    String
    | TokenNotSupported Token

-- instancia show que muestra la información de un error
instance Show LexerError where
    show = \case
        LexerError msg       -> msg
        UnexpectedChar c     -> "unexpected character '" ++ [c] ++ "'"
        StringError str      -> "missing matching quotation mark for string " ++ show str
        TokenNotSupported tk -> show tk ++ " is not supported yet"

-- función que devuelve la posición de un error
errorPos :: Error -> Position
errorPos = \case
    LError p _ -> p