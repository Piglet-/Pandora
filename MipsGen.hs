module MipsGen ()
where

import qualified Data.Map as DMap
import Control.Monad.RWS
import qualified Data.Sequence as DS

type MipsMonad = RWS String MIPS MState 

type MIPS = DS.Sequence (MInstructions)

type MState = {
	tsyt  		:: Zipper
   	, tsrt  	:: Zipper 
   	, regDesc 	:: RegDesTable
}

data RegDescriptor = RegDescriptor 
	{ values 		:: [Reference]
	, genPurpose 	:: Bool
	, using 		:: Bool
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

