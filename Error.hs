{-# LANGUAGE LambdaCase #-}

------------- Módulo que representa los errores lexicográficos ----------------
module Error
    ( isTokenError
    , module Lexeme
    ) where

import  Lexeme
import  Data.Function (on)


-- función que determina si un token es un error lexicográfico
isTokenError :: Lexeme Token -> Bool
isTokenError (Lexeme (TokenError _) _)    = True
isTokenError (Lexeme (TokenIntError _) _) = True
isTokenError (Lexeme TokenBadComment _)   = True
isTokenError (Lexeme TokenStringError _)   = True
isTokenError _                            = False
