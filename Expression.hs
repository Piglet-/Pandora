module Expression 
    ( Expression(..)
    , Operator (..)
    ) where

import Position

data Expression 
    = BoolL     Bool        Position
    | IntL      Int         Position
    | FloatL    Float       Position
    | CharL     Char        Position
    | StringL   String      Position
    | VoidL     Position
    | IdL       String      Position
    | ExpBin    Operator    Expression      Expression Position
    | ExpUna    Operator    Expression      Position
    | Index     Expression  [Expression]    Position
    | FCall     Expression  [Expression]    Position
    | CFCall    Expression  Expression      Position
    | AccsA     Expression  [Expression]    Position
    | AccsS     Expression  [Expression]    Position
    | NoneE
    deriving(Show, Eq)

data Operator 
    = Plus 
    | Minus
    | Mul 
    | Slash 
    | Div
    | Mod 
    | Power 
    | Arrow
    | Gt
    | Lt
    | GEt
    | LEt
    | Equal
    | Inequal
    | And 
    | Or 
    | Not
    deriving(Eq)

instance Show Operator where 
    show Plus       = "+"
    show Minus      = "-"
    show Mul        = "*"
    show Slash      = "/"
    show Div        = "div"
    show Mod        = "mod"
    show Power      = "^"
    show Arrow      = "->"
    show Gt         = ">"
    show Lt         = "<"
    show GEt        = ">="
    show LEt        = "<="
    show Equal      = "=="
    show Inequal    = "/="
    show And        = "and"
    show Or         = "or"
    show Not        = "not"

