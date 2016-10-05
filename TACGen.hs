module TACGen 
    ( initTAC
    , initTACState
    , getAssign
    , listTAC
    , emptyTACState
    , TACMonad (..)
    )
where

import TAC
import Type
import SymbolTable
import Position
import Control.Monad.RWS
import Data.Maybe
import qualified Data.Foldable as FB
import qualified Data.Sequence as DS
import qualified Data.Map.Strict as DMap

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
    AsngL ex@(IdL s e ps) e2 p -> if (isBool e2) 
        then do
            trueL   <- newLabel
            falseL  <- newLabel
            jumpingCode e2 trueL falseL
        else do
            const <- getReference e2
            add <- getAddr ex
            let assgn = AssignU LPoint add const
            tell $ DS.singleton assgn
            return $ assgn
    AsngL ex@(AccsA s e ps) e2 p -> if (isBool e2) 
        then do
            trueL   <- newLabel
            falseL  <- newLabel
            jumpingCode e2 trueL falseL
        else do 
            const <- getReference e2
            add <- getAddr ex
            let assgn = AssignU LPoint add const
            tell $ DS.singleton assgn
            return $ assgn
    AsngL ex@(AccsS s e ps) e2 p -> if (isBool e2) 
        then do
            trueL   <- newLabel
            falseL  <- newLabel
            jumpingCode e2 trueL falseL
        else do 
            const <- getReference e2
            add <- getAddr ex
            let assgn = AssignU LPoint add const
            tell $ DS.singleton assgn
            return $ assgn
    p   ->  do 
            let assgn = Assign (Constant $ ValString (show p)) (Constant $ ValString "yo tampoco")
            tell $ DS.singleton assgn
            return $ assgn

getReference :: Expression -> TACMonad Reference
getReference exp = case exp of
    BoolL  b p  -> return $ Constant $ ValBool  b
    IntL   i p  -> return $ Constant $ ValInt   i 
    FloatL f p  -> return $ Constant $ ValFloat f
    CharL  c p  -> return $ Constant $ ValChar  c 
    StringL s p -> return $ Constant $ ValString s

    ex@(IdL s e p) -> do
        add <- getAddr ex
        return $ add

    ex@(AccsA s e p) -> do 
        add <- getAddr ex
        temp <- newTemp
        let assgn = AssignU RPoint temp add
        tell $ DS.singleton assgn
        return $ temp

    ex@(AccsS s e p) -> 
        do 
            temp <- getAddr ex
            temp2 <- newTemp
            let assgn = AssignU RPoint temp2 temp
            tell $ DS.singleton assgn
            return $ temp2
        --temp <- newTemp
        --let assgn = AssignU RPoint temp add
        --tell $ DS.singleton assgn
        --return $ temp 

    --ex@(AccsP e i p ) -> do 


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
    IdL s (Entry t _ sz o) _ -> 
        do  temp <- newTemp 
            let assgn = AssignB AddI temp (Constant (ValString "fp")) (Constant (ValInt o))
            tell $ DS.singleton assgn
            return $ temp
    AccsA (IdL st (Entry t _ s o) _) es _ -> 
        do  arrayAcc <- auxArray st t es
            temp1 <- newTemp
            temp2 <- newTemp
            let assgn1 = AssignB AddI temp1 (Constant (ValString "fp")) (Constant (ValInt o)) -- No se si es un Addi o RArray
            let assgn2 = AssignB AddI temp2 temp1 arrayAcc
            tell $ DS.singleton assgn1
            tell $ DS.singleton assgn2
            return $ temp2
    AccsS ex@(IdL st (Entry _ _ s o) _) es _ -> do aux ex es
            --temp1 <- newTemp
           -- temp2 <- newTemp
          --  let assgn1 = AssignB AddI temp1 (Constant (ValString "fp")) (Constant (ValInt o))
            --let assgn2 = AssignB AddI temp2 temp1 structAcc
           -- tell $ DS.singleton assgn1
           -- tell $ DS.singleton assgn2
            

aux :: Expression -> [Expression] -> TACMonad Reference
aux (IdL st (Entry _ _ s o) _) es = do
    temp1 <- newTemp
    let assgn = AssignB AddI temp1 (Constant (ValString "fp")) (Constant(ValInt o))
    let offs = map offsetCal es
    tell $ DS.singleton assgn
    auxStruct temp1 offs

auxStruct :: Reference -> [Int]-> TACMonad Reference
auxStruct r [o] = do 
    temp <- newTemp 
    let assgn = AssignB AddI temp r (Constant (ValInt o))
    tell $ DS.singleton assgn
    return $ temp
auxStruct r (o:os) = do
    temp <- newTemp 
    temp2 <- newTemp
    let assgn = AssignB AddI temp r (Constant (ValInt o))
    let assgn2 = AssignU RPoint temp2 temp
    tell $ DS.singleton assgn
    tell $ DS.singleton assgn2
    auxStruct temp2 os

auxArray :: String -> Type-> [Expression] -> TACMonad Reference
auxArray s (ArrayT d t) [e] = do
    symt    <- get 
    const1  <- getReference $ e
    temp1   <- newTemp
    let assgn = AssignB MulI temp1 (Constant (ValInt (typeSize' t (tsyt symt)))) const1
    tell $ DS.singleton assgn
    return $ temp1

auxArray s (ArrayT d t)(e:es) = do
    const1  <- getReference $ e
    temp1   <- newTemp
    let assgn = AssignB MulI temp1 (Constant (ValInt d)) const1
    tell $ DS.singleton assgn
    auxArray' s t es temp1

auxArray':: String -> Type-> [Expression] -> Reference -> TACMonad Reference
auxArray' s (ArrayT d t) [e] r = do
    symt    <- get 
    const1  <- getReference $ e
    temp1   <- newTemp
    temp2   <- newTemp
    let assgn = AssignB MulI temp1 (Constant (ValInt (typeSize' t (tsyt symt)))) const1
    let assgn2 = AssignB AddI temp2 temp1 r
    tell $ DS.singleton assgn
    tell $ DS.singleton assgn2
    return $ temp2

auxArray' s (ArrayT d t)(e:es) r = do
    const1  <- getReference $ e
    temp1   <- newTemp
    temp2   <- newTemp
    let assgn = AssignB MulI temp1 (Constant (ValInt d)) const1
    let assgn2 = AssignB AddI temp2 temp1 r
    tell $ DS.singleton assgn
    tell $ DS.singleton assgn2
    auxArray' s t es temp2

typeSize' (FuncT t ts ast) z    = typeSize' t z
typeSize' (ProcT t ts ast) z    = typeSize' t z
typeSize' (TypeT s) z           = sm
    where (Entry t p sm o)      = fst $ fromJust $ lookupS s z
typeSize' (StructT m) z         = structSize m z
typeSize' (UnionT m) z          = unionSize m z 
typeSize' t z                   = typeSize t 

structSize m z                          = DMap.foldl (structS z) 0 m
structS z n (Entry (TypeT s) p sz off)  = n + sm
    where (Entry t p sm o)              = fst $ fromJust $ lookupS s z
structS z n (Entry t p sz off)          = n + typeSize' t z

unionSize m z                           = DMap.foldl (unionS z) 0 m
unionS z n (Entry (TypeT s) p sz off)   = if n > sm then n else sm
    where (Entry t p sm o)              = fst $ fromJust $ lookupS s z
unionS z n (Entry t p sz off)           = if n > typeSize' t z then n else typeSize' t z  

isBool :: Expression -> Bool
isBool (BoolL b p)                     = True
isBool (ExpUna Not _ p)              = True
isBool (IdL s (Entry t p sz o) po)   = (t == BoolT)
isBool (AccsA e es p)               = isBool e
isBool (AccsS e es p)               = isBool (head $ reverse es)
isBool (ExpBin op _ _ p )             = case op of
                Gt _        -> True
                Lt _        -> True 
                GEt _       -> True
                LEt _       -> True
                Equal _     -> True
                Inequal _   -> True
                And         -> True
                Or          -> True
                _           -> False
isBool _                            = False


jumpingCode :: Expression -> Label -> Label -> TACMonad Ins
jumpingCode e tl fl = case e of 
    BoolL t p-> do 
        let goto = Goto (Just (if t then tl else fl))
        tell $ DS.singleton goto 
        return goto

    ExpBin op e1 e2 p-> case op of
        And  -> do
            rLabel <- newLabel
            jumpingCode e1 rLabel fl
            jumpingCode e2 tl fl 
        Or   -> do
            rLabel <- newLabel
            jumpingCode e1 tl rLabel
            jumpingCode e2 tl fl

        _    -> do
            expl <- getReference e1
            expr <- getReference e2
            let ifgoto  = IfGoto (toRel op) expl expr (Just tl)
            tell $ DS.singleton ifgoto
            let goto    = Goto (Just fl)
            tell $ DS.singleton goto
            return goto

    ExpUna op e1 p-> do 
        jumpingCode e1 fl tl

    --ex@(IdL s e p) tl fl -> do
    --    let goto = Goto 

toRel:: Operator -> Relation
toRel o = case o of 
    Gt _    -> GtT
    Lt _    -> LtT
    GEt _   -> Ge
    LEt _   -> Le
    Equal _ -> Eq
    Inequal _ -> Ne

offsetCal :: Expression -> Int 
offsetCal (IdL _ (Entry _ _ _ o) _) = o 


assing = AsngL (StringL "x" (Position (4,2))) (AccsA (IdL "a" (Entry (ArrayT 2 (ArrayT 1 IntT)) (Position (2,3)) 4 5) (Position (8,9))) [(IntL 2 (Position (7,8))), (ExpBin (Minus IntT) (IntL 5 (Position(4,5))) (IntL 5 (Position(4,5))) (Position(4,4)))] (Position (4,6))) (Position (4,3))
assing2 = AsngL (StringL "x" (Position (4,2))) (ExpBin (Minus IntT) (ExpBin (Minus IntT) (IntL 5 (Position(4,5))) (IntL 5 (Position(4,5))) (Position(4,4))) (IntL 5 (Position(4,5))) (Position(4,4))) (Position (4,3))
assing3 = AsngL (StringL "x" (Position (4,2))) (AccsS (IdL "a" (Entry (StructT (DMap.insert ("otraCosa") (Entry (TypeT "otraCosa") (Position (2,3)) 4 10) (DMap.singleton "cosa" (Entry (TypeT "cosa") (Position (2,3)) 4 6)))) (Position (2,3)) 4 5) (Position (8,9))) [(IdL "cosa" (Entry (TypeT "cosa") (Position (2,3)) 4 6) (Position (8,9))),(IdL "otraCosa" (Entry (TypeT "otraCosa") (Position (2,3)) 4 10) (Position (8,9))) ] (Position (4,6))) (Position (4,3))



assign4 = AsngL (StringL "x" (Position (4,2))) (ExpBin (Gt IntT) (IntL 5 (Position(4,5))) (IntL 6 (Position(4,5))) (Position(4,4))) (Position (4,3))

printTac = do 
    let (state, bita) = execRWS (FB.mapM_ getAssign (DS.singleton assign4)) "" (TACState emptyZipper emptyZipper (AST []) 0 0)
    putStrLn $ show bita

emptyTACState = TACState emptyZipper emptyZipper (AST []) 0 0

listTAC :: AST -> [Instructions]
listTAC (AST ins) = ins
