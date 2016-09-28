module TACGen 
    ( initTAC
    , initTACState
    , TACMonad (..)
    )
where

import TAC
import Type
import SymbolTable
import Position
import Control.Monad.RWS
import qualified Data.Sequence as DS

type TACMonad = RWS TACReader TAC TACState 

type TACReader = ()

data TACState = 
    TACState 
        { tsyt  :: Zipper
        , tsrt  :: Zipper
        , tast  :: AST
        , temp  :: Int
        , label :: Int
        } 

initTAC :: TAC 
initTAC = DS.empty

initTACState :: State -> TACState
initTACState sta = 
    TACState
        { tsyt  = syt sta
        , tsrt  = srt sta
        , tast  = ast sta 
        , temp  = 0
        , label = 0
        } 

newLabel :: TACMonad Label 
newLabel = do 
    newl <- liftM succ $ gets label
    modify $ \x -> x { label = newl }
    return $ Label newl

newTemp :: TACMonad Reference
newTemp = do 
    newt <- liftM succ $ gets temp
    modify $ \x -> x { temp = newt }
    return $ Temp newt

getAssign :: Instructions -> TACMonad Ins
getAssign ins = case ins of
    AsngL (StringL s ps) e2 p -> do
        const <- getReference e2
        let assgn = Assign (Constant $ ValString s) const
        tell $ DS.singleton assgn
        return $ assgn

getReference :: Expression -> TACMonad Reference
getReference exp = case exp of
    BoolL  b p -> return $ Constant $ ValBool  b
    IntL   i p -> return $ Constant $ ValInt   i 
    FloatL f p -> return $ Constant $ ValFloat f
    CharL  c p -> return $ Constant $ ValChar  c 

assing = AsngL (StringL "x" (Position (4,2))) (IntL 5 (Position(4,5))) (Position (4,3))

makeBOpp :: Operator -> BinOp
makeBOpp op = case op of
    Plus t  -> if t == IntT then AddI else AddF 
    Minus t -> if t == IntT then SubI else SubF
    Mul t   -> if t == IntT then MultI else MultF
    Slash t -> if t == IntT then DivI else DivF
    Div     -> DivI
    Mod t   -> Mod
    Power t -> Pow
    And     -> And
    Or      -> Or