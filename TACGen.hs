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

   -- IdL s e p   -> do 
     --   add <- getAddr exp 

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

assing = AsngL (StringL "x" (Position (4,2))) (IntL 5 (Position(4,5))) (Position (4,3))
assing2 = AsngL (StringL "x" (Position (4,2))) (ExpBin (Minus IntT) (ExpBin (Minus IntT) (IntL 5 (Position(4,5))) (IntL 5 (Position(4,5))) (Position(4,4))) (IntL 5 (Position(4,5))) (Position(4,4))) (Position (4,3))

printTac = do 
    let (state, bita) = execRWS (getAssign assing2) "" (TACState emptyZipper emptyZipper (AST []) 0 0)
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


-- mateo generaliza en Access los idL, accesos a areglos, accesos a strucuts y a apuntadores
-- calcula la dir del valor que queremos
-- return Address s r
-- con s el string de la variable y r la referencia que es 
-- un Reference Constant Int que guarda el offset (ya calculado
-- con otra funcion).
getAddr :: Expression -> TACMonad Reference
getAddr = undefined
