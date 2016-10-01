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

type TACReader = String

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
    BoolL  b p  -> return $ Constant $ ValBool  b
    IntL   i p  -> return $ Constant $ ValInt   i 
    FloatL f p  -> return $ Constant $ ValFloat f
    CharL  c p  -> return $ Constant $ ValChar  c 
    StringL s p -> return $ Constant $ ValString s

    ex@(AccsA s e p) -> do 
        add <- getAddr ex
        return $ add 

    ex@(AccsS s e p) -> do 
        add <- getAddr ex
        return $ add 

    ExpBin op e1 e2 p -> do 
        const1 <- getReference e1
        const2 <- getReference e2
        nt <- newTemp
        let assgn = AssignB (makeBOpp op) nt const1 const2
        tell $ DS.singleton assgn
        return $ nt

    ExpUna op e1 p -> do
        const1 <- getReference e1
        nt <- newTemp
        let assgn = AssignU (makeUOpp op) nt const1
        tell $ DS.singleton assgn
        return $ nt

assing = AsngL (StringL "x" (Position (4,2))) (AccsA (IdL "a" (Entry (ArrayT 2 IntT) (Position (2,3)) 4 5) (Position (8,9))) [(IntL 2 (Position (7,8))), (ExpBin (Minus IntT) (IntL 5 (Position(4,5))) (IntL 5 (Position(4,5))) (Position(4,4)))] (Position (4,6))) (Position (4,3))
assing2 = AsngL (StringL "x" (Position (4,2))) (ExpBin (Minus IntT) (ExpBin (Minus IntT) (IntL 5 (Position(4,5))) (IntL 5 (Position(4,5))) (Position(4,4))) (IntL 5 (Position(4,5))) (Position(4,4))) (Position (4,3))

printTac = do 
    let (state, bita) = execRWS (getAssign assing) "" (TACState emptyZipper emptyZipper (AST []) 0 0)
    putStrLn $ show bita

emptyZipper :: Zipper
emptyZipper = focus $ emptyST emptyScope

makeBOpp op = case op of
    Plus t  -> if t == IntT then AddI else AddF 
    Minus t -> if t == IntT then SubI else SubF
    Mul t   -> if t == IntT then MulI else MulF
    Slash t -> if t == IntT then DivI else DivF
    Div     -> DivI
    Mod t   -> ModT
    Power t -> PowT
    And     -> AndT
    Or      -> OrT

makeUOpp op = case op of
    Not -> NotT
    Minus t -> if t == IntT then NegI else NegF

getAddr :: Expression -> TACMonad Reference
getAddr e = case e of 
    IdL s (Entry t _ sz o) _ -> return $ Address s (Constant (ValInt o))
    AccsA (IdL st (Entry _ _ s o) _) es _ -> do aux (Constant (ValString st)) es
    AccsS (IdL st (Entry _ _ s o) _) es _ -> do aux (Constant (ValString st)) es -- es como los arreglos pero en a[d] d es el offset del campo al que se accede

aux :: Reference -> [Expression] -> TACMonad Reference
aux r [] = return $ r
aux r (e:es) = do 
    const1 <- getReference $ e
    temp1 <- newTemp
    let assgn = AssignB RArray temp1 r const1
    tell $ DS.singleton assgn
    aux temp1 es    
