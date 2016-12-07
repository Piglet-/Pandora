module MipsGen 
( MipsMonad (..)
, emptyMIPSState
, buildMips
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
    Tac.AssignB op res r1 r2 -> do 
        rz <- getReg res
        ry <- getReg r2
        rx <- getReg r1
        let assgn = builBOp op rz rx ry
        tell $ DS.singleton assgn
        return assgn

    Tac.Comment str -> do
        tell $ DS.singleton (Comment str)
        return (Comment str)

    Tac.PutLabel (Tac.Label str) -> do
        tell $ DS.singleton (PutLabel "L" str)
        return (PutLabel "L" str)

    Tac.AssignU op res r1 -> do
        ry <- getReg res
        rx <- getReg r1
        let assgn = builBOpU op ry rx
        tell $ DS.singleton assgn
        return assgn

builBOp :: Tac.BinOp -> Register -> Register -> Register -> MInstruction
builBOp op res r1 r2 = case op of 
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

builBOpU :: Tac.UnOp -> Register -> Register -> MInstruction
builBOpU op res r1 = case op of
    Tac.NotT -> Not res r1
    Tac.NegI -> Negi res r1 
    Tac.NegF -> Negf res r1
    Tac.LPoint -> Store res r1

emptyZipper :: Zipper
emptyZipper = focus $ emptyST emptyScope

data Reason = Read 
            | Write
            deriving (Eq)

getReg ::  Tac.Reference -> MipsMonad (Register)
getReg ref = case ref of
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
                        return reg
            return reg

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

