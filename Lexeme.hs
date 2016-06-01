------------------- Módulo que representa los lexemas -------------------------
module Lexeme
    ( Lexeme(..)
    , module Position 
    , module Tokens
    ) where

import Position
import Tokens

-- tipo de datos Lexeme compuesto por un token y su posición
data Lexeme t = Lexeme
    {
    	token :: Token, 
    	pos :: Position
     
    } deriving Eq

-- instancia show para la información de un lexema
instance Show t => Show (Lexeme t) where
    show (Lexeme t p) = show t ++ show p 