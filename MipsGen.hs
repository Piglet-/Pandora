module MipsGen 
( MipsMonad (..)
, emptyMIPSState
, buildMips
, initMIPSState
)
where

import qualified Data.Map as DMap
import Control.Monad.RWS
import qualified Data.Sequence as DS
import qualified TAC as Tac
import Mips
import SymbolTable
import Type (Entry)
import qualified Data.Map.Strict as Map

type MipsMonad = RWS MipsReader MIPS MState 

type MipsReader = String

type MIPS = DS.Seq MInstruction

data MState = Mstate 
    { tsyt  	:: Zipper
   	, tsrt  	:: Zipper 
   	, regDesc 	:: RegDesTable
    , spillC    :: Int
    , strHash   :: DMap.Map String String
    , nStr      :: Int
    }

data RegDescriptor = RegDescriptor 
	{ values 		:: [Tac.Reference]
	, genPurpose 	:: Bool
	, using 		:: Bool
	}

emptyMIPSState = Mstate emptyZipper emptyZipper initRegDescriptors 0

initMIPSState :: State -> MState
initMIPSState sta = 
    Mstate
        { tsyt     = syt sta
        , tsrt     = srt sta
        , regDesc  = initRegDescriptors 
        , spillC   = 0
        , strHash  = DMap.empty
        , nStr     = 0 
        } 

type RegDesTable = DMap.Map Register RegDescriptor

initRegDescriptors = DMap.fromList
    [ (V1, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T0, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T1, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T2, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T3, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T4, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T5, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T6, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T7, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T8, RegDescriptor { values = [], genPurpose = True, using = False})
    , (T9, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S0, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S1, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S2, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S3, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S4, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S5, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S6, RegDescriptor { values = [], genPurpose = True, using = False})
    , (S7, RegDescriptor { values = [], genPurpose = True, using = False})
    ]

buildMips :: Tac.Ins -> MipsMonad MInstruction
buildMips ins = case ins of

    Tac.TPreamble -> do
        fillStringHash
        tell $ DS.singleton (Preamble ".data")
        putString
        tell $ DS.singleton (Preamble ".text")
        tell $ DS.singleton (Preamble ".align 2")
        return $ Preamble ".text"

    Tac.AssignB op res r1 r2 -> do 
        tell $ DS.singleton (Comment (show r1))
        rz <- getReg False res
        ry <- getReg True r2
        rx <- getReg True r1
        let assgn = buildBOp op rz rx ry
        tell $ DS.singleton assgn
        return assgn

    Tac.Call r l i -> do
        tell $ DS.singleton (Jal l)
        ret <- getReg False r
        tell $ DS.singleton (Move ret A3)
        return (Comment "call")

    Tac.CallP l i -> do
        tell $ DS.singleton (Jal l)
        return (Comment "calp")

    Tac.Comment str -> do
        tell $ DS.singleton (Comment str)
        return (Comment str)

    Tac.PutLabel (Tac.Label str) -> do
        tell $ DS.singleton (PutLabel str)
        return (PutLabel str)

    Tac.AssignU op res r1 -> do
        ry <- getReg False res
        rx <- getReg True r1
        let assgn = buildBOpU op ry rx
        tell $ DS.singleton assgn
        return assgn

    Tac.Assign res r1 -> do
        ry <- getReg False res
        rx <- getReg True r1
        let assgn = Move ry rx
        tell $ DS.singleton assgn
        return assgn

    Tac.Goto label -> do
        case label of 
            (Just l) -> do 
                let assgn = B (show l) 
                tell $ DS.singleton assgn
                return $ assgn
            _        -> error "Label doesn't exist"

    Tac.IfTrue ref label -> do
        case label of 
            (Just l) -> do 
                rx <- getReg False ref 
                let assgn = Bne rx Zero (show l) 
                tell $ DS.singleton assgn
                return $ assgn
            _        -> error "Label doesn't exist"

    Tac.IfFalse ref label -> do
        case label of 
            (Just l) -> do 
                rx <- getReg False ref 
                let assgn = Beq rx Zero (show l) 
                tell $ DS.singleton assgn
                return $ assgn
            _        -> error "Label doesn't exist"

    Tac.IfGoto rel r1 r2 label -> do
        case label of 
            (Just l) -> do 
                ry <- case r2 of 
                    Tac.Constant v -> do 
                        ry2 <- getReg True r2
                        rx2 <- buildRef r2
                        let assgn = Li ry2 rx2
                        return ry2
                    _              -> getReg False r2
                rx <- case r1 of 
                    Tac.Constant v -> do 
                        ry1 <- getReg True r1
                        rx1 <- buildRef r1
                        let assgn = Li ry1 rx1
                        return ry1
                    _              -> getReg False r1
                let assgn = buildRel rel ry rx l
                tell $ DS.singleton assgn
                return $ assgn 
            _ -> error " Label doesn't exist"

    Tac.IfNotGoto rel r1 r2 label -> do
        case label of 
            (Just l) -> do 
                ry <- case r2 of 
                    Tac.Constant v -> do 
                        ry2 <- getReg True r2
                        rx2 <- buildRef r2
                        let assgn = Li ry2 rx2
                        return ry2
                    _              -> getReg False r2
                rx <- case r1 of 
                    Tac.Constant v -> do 
                        ry1 <- getReg True r1
                        rx1 <- buildRef r1
                        let assgn = Li ry1 rx1
                        return ry1
                    _              -> getReg False r1
                let assgn = buildNotRel rel ry rx l
                tell $ DS.singleton assgn
                return $ assgn 
            _ -> error " Label doesn't exist"

    Tac.Block -> do
        saveBlock
        tell $ DS.singleton (Comment "Saving variables")
        return $ Comment "Saving variables"

    Tac.Prologue i -> do
        let assgn = Subu SP SP (Const 8) --espacio ra y fp en la pila
        tell $ DS.singleton assgn
        let assgn1 = Sw RA (Indexed 4 SP) -- guarda ra
        tell $ DS.singleton assgn1
        let assgn2 = Sw FP (Indexed 0 SP) -- guarda fp
        tell $ DS.singleton assgn2
        let assgn3 = Move FP SP -- nuevo fp
        tell $ DS.singleton assgn3
        let assgn4 = Subu SP SP (Const i) -- espacio para variable locales
        tell $ DS.singleton assgn4
        return $ assgn4 

    Tac.Epilogue i -> do
        let assgn = (Comment "EPILOGO")
        let assgn1 = Lw RA (Indexed 4 FP)
        let assgn2 = Lw FP (Indexed 0 FP)
        let assgn3 = Jr RA
        tell $ DS.singleton assgn
        tell $ DS.singleton assgn1
        tell $ DS.singleton assgn2
        tell $ DS.singleton assgn3
        return $ assgn

    Tac.Param r -> do
        tell $ DS.singleton (Comment "PUSH")
        tell $ DS.singleton (Subu SP SP (Const 4)) -- decrementar la pila para hacer espacio
        reg <- getReg True r
        let assgn = (Sw reg (Indexed 0 SP))
        tell $ DS.singleton assgn
        return $ assgn

    Tac.CleanUp i -> do
        tell $ DS.singleton (Comment "CleanUp")
        return $ Comment "Saving variables"
    
    Tac.WriteS s -> do
        hs <- gets strHash
        let aux = maybe "" id (DMap.lookup s hs )
        tell $ DS.singleton (Li V0 (Const 4))
        let assgn = (La A0 aux)
        tell $ DS.singleton assgn
        tell $ DS.singleton (Syscall)
        return $ assgn

    Tac.WriteI r -> do
        reg <- getReg False r
        tell $ DS.singleton (Move A0 reg)
        tell $ DS.singleton (Li V0 (Const 1))
        tell $ DS.singleton Syscall
        return $ Syscall

    Tac.ReadI r -> do
        reg <- getReg True r
        tell $ DS.singleton (Li V0 (Const 5))
        tell $ DS.singleton (Syscall)
        tell $ DS.singleton (Sw V0 (Indexed 0 reg))
        return $ Syscall

    Tac.Return mr l -> do
        let assgn = Jal l 
        case mr of
            Just r -> do 
                reg <- case r of 
                    Tac.Constant v -> do 
                        ry2 <- getReg True r
                        rx2 <- buildRef r
                        let assgn = Li ry2 rx2
                        return ry2
                    _ -> getReg False r
                tell $ DS.singleton (Move A3 reg)
                tell $ DS.singleton assgn
                return assgn
            _   -> do
                tell $ DS.singleton assgn
                return assgn
        return assgn

    Tac.Exit -> do
        let assgn = Li V0 (Const 10) 
        tell $ DS.singleton assgn
        tell $ DS.singleton Syscall
        return assgn

    s -> do return $ Comment (show s)

buildBOp :: Tac.BinOp -> Register -> Register -> Register -> MInstruction
buildBOp op res r1 r2 = case op of 
    Tac.AddI -> Add res r1 r2  
    Tac.AddF -> AddS res r1 r2
    Tac.SubI -> Sub res r1 r2
    Tac.SubF -> SubS res r1 r2
    Tac.MulI -> Mul res r1 r2
    Tac.MulF -> MulS res r1 r2
    Tac.DivI -> Div res r1 r2
    Tac.DivF -> DivS res r1 r2
    --Tac.ModT -> Mfhi res r1 r2
    Tac.AndT -> And res r1 r2
    Tac.OrT  -> Or res r1 r2


buildBOpU :: Tac.UnOp -> Register -> Register -> MInstruction
buildBOpU op res r1 = case op of
    Tac.NotT -> Not res r1
    Tac.NegI -> Negi res r1 
    Tac.NegF -> Negf res r1
    Tac.LPoint -> Sw r1 (Indexed 0 res) 
    Tac.RPoint -> Lw res (Indexed 0 r1)

--Acomodar r1 y r2 en las funciones que usan esta funcion
buildRel :: Tac.Relation -> Register -> Register -> Tac.Label -> MInstruction
buildRel rel r2 r1 l = case rel of
    Tac.Eq  -> Beq r1 r2 (show l)
    Tac.GtT -> Bgt r1 r2 (show l)
    Tac.LtT -> Blt r1 r2 (show l)
    Tac.Ne  -> Bne r1 r2 (show l)
    Tac.Ge  -> Bge r1 r2 (show l)
    Tac.Le  -> Ble r1 r2 (show l)

--Acomodar r1 y r2 en las funciones que usan esta funcion
buildNotRel :: Tac.Relation -> Register -> Register -> Tac.Label -> MInstruction
buildNotRel rel r2 r1 l = case rel of
    Tac.Eq  -> Bne r1 r2 (show l)
    Tac.GtT -> Ble r1 r2 (show l)
    Tac.LtT -> Bge r1 r2 (show l)
    Tac.Ne  -> Beq r1 r2 (show l)
    Tac.Ge  -> Blt r1 r2 (show l)
    Tac.Le  -> Bgt r1 r2 (show l)

emptyZipper :: Zipper
emptyZipper = focus $ emptyST emptyScope

data Reason = Read 
            | Write
            deriving (Eq)

getReg :: Bool -> Tac.Reference -> MipsMonad (Register)
getReg read ref = case ref of
    Tac.FP -> return FP
    _   -> do
            reg <- do 
                mReg <- findRegContent ref
                case mReg of
                    Just reg    -> return reg
                    Nothing     -> do
                        mEReg <- findEmptyReg
                        reg <- case mEReg of
                            Just empty  -> return empty
                            Nothing     -> do
                                count <- gets spillC
                                regi <- makeSpill count
                                return regi

                        usingRef ref reg 
                        when (read) $ do
                            op <- buildRef ref
                            tell $ DS.singleton (Li reg op)
                        return reg
            return reg

buildRef :: Tac.Reference -> MipsMonad (Operand)
buildRef ref = case ref of 
    Tac.Address s r -> do 
        off <- offset
        return $ Indexed off FP
            where 
                offset = case r of
                    Tac.Constant (Tac.ValInt i) -> return i
                    _ -> error "Address is not a constant"  
    Tac.Constant value -> do 
        case value of  
            Tac.ValInt i -> return $ Const i
            Tac.ValBool b -> if b then return (Const 1) else return (Const 0)
            _ -> error (show ref) 
    _ -> error (show ref)

makeSpill:: Int -> MipsMonad (Register)
makeSpill count = do
    descrM      <- gets regDesc
    let newRegD = DMap.updateAt (\ _ _ -> Just(RegDescriptor { values = [], genPurpose = True, using = False})) count descrM
    modify $ \x -> x { regDesc = newRegD, spillC = count + 1 }
    let (reg, desc) = DMap.elemAt count newRegD
    return reg

findRegContent :: Tac.Reference-> MipsMonad (Maybe Register)
findRegContent ref = gets regDesc >>= return . Map.foldlWithKey checkReg Nothing
    where
        checkReg Nothing reg regDescrip = if (elem ref (values regDescrip)) then Just reg else Nothing
        checkReg reg@(Just _) _ _ = reg

findEmptyReg :: MipsMonad (Maybe Register)
findEmptyReg = gets regDesc >>= return . Map.foldlWithKey checkReg Nothing
    where
        checkReg mReg keyReg regDescrip = case (mReg, values regDescrip) of
            (Just _, _)         -> mReg
            (Nothing, [])       -> Just keyReg
            (Nothing, values)   -> Nothing


usingRef :: Tac.Reference -> Register -> MipsMonad()
usingRef ref reg = do
    regDescrip <- gets regDesc
    if DMap.member reg regDescrip 
        then modify $ \s -> s {regDesc = DMap.adjust (\rd -> rd { values = ref : values rd}) reg regDescrip }
        else error "Register not exist"

saveBlock :: MipsMonad()
saveBlock = do
    regDescrip <- gets regDesc
    modify $ \s -> s { regDesc = initRegDescriptors, spillC = 0 }


fillStringHash :: MipsMonad() 
fillStringHash = do
    st <- gets tsrt
    let m = getMap st
    let s = DMap.keys m
    mapM_ doinstr s
    return ()

getMap :: Zipper -> (DMap.Map String Entry)
getMap ((SymbolTable _ m _ ),_) = m

doinstr:: String -> MipsMonad(MInstruction)
doinstr s = do
    st <- get
    hs <- gets strHash
    i <- gets nStr
    let t = DMap.insert s ("S" ++ show i) hs
    put st {strHash = t, nStr = (i+1)}
    return $ (Comment "doinstr")

putString:: MipsMonad(MInstruction)
putString = do
    hs <- gets strHash
    let lt = DMap.assocs hs
    mapM_ tellString lt
    return $(Comment "putString")


tellString:: (String, String) -> MipsMonad(MInstruction)
tellString (s1,s2) = do
    let assgn = Asciiz s2 s1
    tell $ DS.singleton assgn
    return $ assgn
