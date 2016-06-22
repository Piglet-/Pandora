------------------- Módulo que representa los lexemas -------------------------
module Lexeme
    ( Lexeme(..)
    , module Position 
    , module Tokens
    , getTkChar
    ,getTkID
    ,getTkInt
    ,getTkFloat
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

getTkID :: Lexeme Token -> String
getTkID (Lexeme (TokenIdent s) p) = s
getTkID (Lexeme (TokenString s) p)= s

getTkInt :: Lexeme Token -> Int
getTkInt (Lexeme (TokenInt i) p) = i 

getTkFloat :: Lexeme Token -> Float 
getTkFloat (Lexeme (TokenFloat f) p) = f

getTkChar :: Lexeme Token -> Char 
getTkChar (Lexeme (TokenChar c) p) = c