
module Lexeme
    ( Lexeme(..)
    , module Position
    ) where

import Position

data Lexeme t = Lexeme
    {
    	token :: t, 
    	pos :: Position
     
    } deriving Eq

instance Show t => Show (Lexeme t) where
    show (Lexeme t p) = show p ++ " : " ++ show t