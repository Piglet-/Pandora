--------------- Módulo que representa la posición de un token -----------------
module Position
    ( Position(..)
    , line
    , col
    ) where

-- tipo de datos para la posición compuesto por dos enteros que
-- representan la linea y la columna donde se encuentra el token
newtype Position = Position (Int, Int)
  deriving Eq

-- instancia show que muestra los detalles de la posición
instance Show Position where
  show (Position (l, c)) = "\nLocation: Line " ++ show l ++ " Column " ++ show c

-- función que devuelve la línea de un token
line :: Position -> Int
line (Position (l, _)) = l

-- función que devuelve la columna de un token
col :: Position -> Int
col (Position (_, c)) = c