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

type MipsMonad = RWS MipsReader MIPS MState 

type MipsReader = String

type MIPS = DS.Seq MInstruction

data MState = Mstate 
    { tsyt  	:: Zipper
   	, tsrt  	:: Zipper 
   	, regDesc 	:: RegDesTable
    }

data RegDescriptor = RegDescriptor 
	{ values 		:: [Tac.Reference]
	, genPurpose 	:: Bool
	, using 		:: Bool
	}

emptyMIPSState = Mstate emptyZipper emptyZipper initRegDescriptors

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
        let assgn = builBOp op res r1 r2
        tell $ DS.singleton assgn
        return assgn

builBOp :: Tac.BinOp -> Tac.Reference -> Tac.Reference -> Tac.Reference -> MInstruction
builBOp op res r1 r2 = case op of 
    Tac.AddI -> Add T0 T1 T2  
    Tac.AddF -> AddS T0 T1 T2
    Tac.SubI -> Sub T0 T1 T2
    Tac.SubF -> SubS T0 T1 T2
    Tac.MulI -> Mul T0 T1 T2
    Tac.MulF -> MulS T0 T1 T2
    Tac.DivI -> Div T0 T1 T2
    Tac.DivF -> DivS T0 T1 T2 
    Tac.ModT -> Mfhi T0 
--    | PowT
--    | AndT 
--    | OrT
--    | LArray
--    | RArray    

emptyZipper :: Zipper
emptyZipper = focus $ emptyST emptyScope