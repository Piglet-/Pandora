
module Lexeme
    ( Lexeme(..)
    , module Position
    ) where

import Position
import Tokens

data Lexeme t = Lexeme
    {
    	token :: Token, 
    	pos :: Position
     
    } deriving Eq

instance Show t => Show (Lexeme t) where
    show (Lexeme t p) = "\n Token: " ++ show t ++ " \nLocation: " ++ show p ++ "\n"