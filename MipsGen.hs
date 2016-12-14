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
import qualified Data.Map.Strict as Map

type MipsMonad = RWS MipsReader MIPS MState 

type MipsReader = String

type MIPS = DS.Seq MInstruction

data MState = Mstate 
    { tsyt  	:: Zipper
   	, tsrt  	:: Zipper 
   	, regDesc 	:: RegDesTable
    , spillC    :: Int
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
        tell $ DS.singleton (Preamble ".text")
        tell $ DS.singleton (Preamble ".align 2")
        tell $ DS.singleton (Preamble ".globl main")
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
        tell $ DS.singleton (Move  ret V0)
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
                ry <- getReg False r2
                rx <- getReg False r1
                let assgn = buildRel rel ry rx l
                tell $ DS.singleton assgn
                return $ assgn 
            _ -> error " Label doesn't exist"

    Tac.IfNotGoto rel r1 r2 label -> do
        case label of 
            (Just l) -> do 
                ry <- getReg False r2
                rx <- getReg False r1
                let assgn = buildNotRel rel ry rx l
                tell $ DS.singleton assgn
                return $ assgn 
            _ -> error " Label doesn't exist"

    Tac.Block -> do
        saveBlock
        tell $ DS.singleton (Comment "Saving variables")
        return $ Comment "Saving variables"

    Tac.Prologue i -> do
        return (Comment "PROLOGO")
        let assgn = Subu SP SP (Const 8) --espacio ra y fp en la pila 
        tell $ DS.singleton assgn
        let assgn1 = Sw FP (Indexed 8 SP) -- guarda fp
        tell $ DS.singleton assgn1
        let assgn2 = Sw RA (Indexed 4 SP) -- guarda ra
        tell $ DS.singleton assgn2
        let assgn3 = Addi FP SP (Const 8) -- nuevo fp
        tell $ DS.singleton assgn3
        let assgn4 = Subu SP SP (Const i) -- espacio para variable locales
        tell $ DS.singleton assgn
        return $ assgn4

    Tac.Epilogue i -> do
        let assgn = (Comment "EPILOGO")
        tell $ DS.singleton assgn
        return $ assgn

    Tac.Param r -> do
        tell $ DS.singleton (Comment "PUSH")
        tell $ DS.singleton (Subu SP SP (Const 4)) -- decrementar la pila para hacer espacio
        reg <- getReg True r
        let assgn = (Sw reg (Indexed 4 SP))
        tell $ DS.singleton assgn
        return $ assgn

    Tac.CleanUp i -> do
        tell $ DS.singleton (Comment "CleanUp")
        return $ Comment "Saving variables"
    

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
    Tac.LPoint -> Sw res (Indexed 0 r1)
    Tac.RPoint -> Lw res (Indexed 0 r1)

buildRel :: Tac.Relation -> Register -> Register -> Tac.Label -> MInstruction
buildRel rel r1 r2 l = case rel of
    Tac.Eq  -> Beq r1 r2 (show l)
    Tac.GtT -> Bgt r1 r2 (show l)
    Tac.LtT -> Blt r1 r2 (show l)
    Tac.Ne  -> Bne r1 r2 (show l)
    Tac.Ge  -> Bge r1 r2 (show l)
    Tac.Le  -> Ble r1 r2 (show l)

buildNotRel :: Tac.Relation -> Register -> Register -> Tac.Label -> MInstruction
buildNotRel rel r1 r2 l = case rel of
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
                            tell $ DS.singleton (Lw reg op)
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
