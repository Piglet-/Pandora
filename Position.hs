module Position
    ( Position(..)
    , line
    , col
    ) where

newtype Position = Position (Int, Int)
  deriving Eq

instance Show Position where
  show (Position (l, c)) = "Line " ++ show l ++ " Column " ++ show c

line :: Position -> Int
line (Position (l, _)) = l

col :: Position -> Int
col (Position (_, c)) = c