module TAC 
	( TAC (..)
	, Label (..)
	, Reference (..)
	, Value (..)
	, Ins (..)
	, BinOp (..)
	, UnOp (..)
	, Relation (..)
	) where

import qualified Data.Sequence as DS
import qualified Data.Foldable as FB
import Data.Binary as Bin
import Control.Monad 

type TAC = DS.Seq Ins

data Ins =  
	Comment 	String
	| PutLabel  Label
	| AssignB 	BinOp Reference Reference Reference
	| AssignU 	UnOp Reference Reference
	| Assign 	Reference Reference
	| Goto 		(Maybe Label)
	| IfTrue	Reference (Maybe Label)
	| IfFalse	Reference (Maybe Label)
	| IfGoto 	Relation Reference Reference (Maybe Label)
	| IfNotGoto	Relation Reference Reference (Maybe Label)
	| Param 	Reference
	| Call 		Reference String  
	| CallP		String 
	| CleanUp	Int 
	| Return 	(Maybe Reference)
	| PrintT	Reference
	| Prologue 	Int
	| Epilogue 	Int
	deriving (Eq)

instance Show Ins where
	show a = case a of
		Comment s 			-> "# " ++ s
		PutLabel l 			-> (show l) ++ " : "
		AssignB o re l r 	-> (show re) ++ " := " ++ (show l) ++ (show o) ++ (show r)
		AssignU (LPoint) r op -> "*" ++ show r ++ " := " ++ (show op) -- op es operando 
		AssignU o r  op 	-> (show r) ++ " := " ++ (show o) ++ (show op)
		Assign 	l r 		-> (show l) ++ " := " ++ (show r)
		Goto 	l 			-> "Goto " ++  showJ l
		IfTrue 	r l 		-> "If " ++ show r ++ " Goto " ++ showJ l 
		IfFalse r l 		-> "If not " ++ show r ++ " Goto " ++ showJ l 
		IfGoto	o r1 r2	l	-> "If " ++ show r1 ++ " " ++ show o ++ " " ++ show r2 ++ " Goto " ++ showJ l
		IfNotGoto o r1 r2 l	-> "If not " ++  show r1 ++ " " ++ show o ++ " " ++ show r2 ++ " Goto " ++ showJ l
		Param r 			-> "Param " ++ show r
		Call r s 			-> show r ++ " := " ++ "call " ++ s  
		CallP s 			-> "Call " ++ s 
		CleanUp i 			-> "CleanUp " ++ show i 
		Return r 			-> "Return " ++ showR r
		PrintT r 			-> "Print " ++ show r 
		Prologue i 			-> "PROLOGUE " ++ show i 
		Epilogue i 			-> "EPILOGUE " ++ show i

instance Binary Ins where
	put (Comment s) 			= putWord8 0 >> put s
	put (PutLabel l) 			= putWord8 50 >> put l
	put (AssignB re o l r) 		= putWord8 1 >> put re >> put o >> put l >> put r
	put (AssignU r o op) 		= putWord8 2 >> put r >> put o >> put op
	put (Assign l r) 			= putWord8 3 >> put l >> put r
	put (Goto 	l)	 			= putWord8 4 >> put l
	put (IfTrue r l) 			= putWord8 51 >> put r >> put l 
	put (IfFalse r l)			= putWord8 52 >> put r >> put l
	put (IfGoto	o r1 r2	l) 		= putWord8 5 >> put o >> put r1 >> put r2 >> put l
	put (IfNotGoto o r1 r2 l) 	= putWord8 43 >> put o >> put r1 >> put r2 >> put l
	put (Param r)				= putWord8 39 >> put r
	put (Call r s ) 			= putWord8 8 >> put r >> put s 
	put (CallP s)				= putWord8 41 >> put s 
	put (CleanUp i)				= putWord8 53 >> put i
	put (Return r)				= putWord8 42 >> put r 
	put (PrintT r) 				= putWord8 9 >> put r
	put (Prologue i)			= putWord8 54 >> put i 
	put (Epilogue i) 			= putWord8 55 >> put i

	get = do 
		    w <- getWord8
		    case w of
		       	0  ->  Bin.get >>= return . Comment
		       	50 ->  Bin.get >>= return . PutLabel
		       	1  ->  makeT4 AssignB
		       	2  ->  makeT3 AssignU
		       	3  ->  makeT2  Assign
		       	4  ->  Bin.get >>= return .  Goto
		       	51 ->  makeT2 IfTrue
		       	52 ->  makeT2 IfFalse
		    	5  ->  makeT4 IfGoto
		    	43 ->  makeT4 IfNotGoto
		    	8  ->  makeT2 Call
		    	41 ->  Bin.get >>= return . CallP
		    	53 ->  Bin.get >>= return . CleanUp
		    	39 ->  Bin.get >>= return . Param
		    	42 ->  Bin.get >>= return . Return
		    	9  ->  Bin.get >>= return . PrintT 
		    	54 ->  Bin.get >>= return . Prologue
		    	55 ->  Bin.get >>= return . Epilogue

makeT2::(Binary a1, Binary a2) => (a1 -> a2 -> r) -> Get r
makeT2 t = liftM2 t Bin.get Bin.get

makeT3::(Binary a1, Binary a2, Binary a3) => (a1 -> a2 -> a3 -> r) -> Get r
makeT3 t = liftM3 t Bin.get Bin.get Bin.get

makeT4::(Binary a1, Binary a2, Binary a3, Binary a4) => (a1 -> a2 -> a3 -> a4 -> r) -> Get r
makeT4 t = liftM4 t Bin.get Bin.get Bin.get Bin.get


newtype Label = Label String deriving (Eq)

instance Show Label where
	show (Label i) = i 

instance Binary Label where
	put (Label l) = put l
	get = do Bin.get >>= return . Label 

data Reference = 
	Address 	String Reference
	| Constant 	Value
	| Temp 		Int
	| FP 		
	deriving(Eq)

instance Show Reference where
	show a = case a of
		Address 	s r 	-> show r -- s ++ " " ++ show r
		Constant 	v  		-> show v
		Temp 		i 		-> "T" ++ show i
		FP 					-> " fp "

instance Binary Reference where
	put (Address s r ) 	= putWord8 10 >> put s >> put r
	put (Constant v) 	= putWord8 11 >> put v
	put (Temp i) 		= putWord8 12 >> put i
	put (FP)			= putWord8 48 

	get = do 
		w <- getWord8
		case w of
			10  -> makeT2 Address
			11 	-> Bin.get >>= return . Constant
			12	-> Bin.get >>= return . Temp
			48 	-> return $ FP
data Value =
	ValInt 		Int
	| ValFloat 	Float
	| ValChar	Char 
	| ValBool	Bool 
	| ValString String
	deriving(Eq)

instance Show Value where
	show a = case a of
		ValInt 		i 	-> show i 
		ValFloat 	f 	-> show f
		ValChar 	c 	-> show c
		ValBool 	b 	-> show b
		ValString 	s	-> s 

instance Binary Value where
	put (ValInt i) 		= putWord8 13 >> put i 
	put (ValFloat f) 	= putWord8 14 >> put f
	put (ValChar c) 	= putWord8 15 >> put c 
	put (ValBool b) 	= putWord8 16 >> put b
	put (ValString s) 	= putWord8 17 >> put s 

	get = do 
		w <- getWord8
		case w of
			13 -> Bin.get >>= return . ValInt
			14 -> Bin.get >>= return . ValFloat
			15 -> Bin.get >>= return . ValChar
			16 -> Bin.get >>= return . ValBool
			17 -> Bin.get >>= return . ValString 

data BinOp =
	AddI 
	| AddF
	| SubI
	| SubF
	| MulI
	| MulF 
	| DivI 
	| DivF 
	| ModT 
	| PowT
	| AndT 
	| OrT
	| LArray
	| RArray
	deriving (Eq)

instance Show BinOp where
	show a = case a of 
		AddI 	-> " +i "
		AddF 	-> " +f "
		SubI 	-> " -i "
		SubF 	-> " -f "
		MulI 	-> " *i "
		MulF 	-> " *f "
		DivI 	-> " /i "
		DivF 	-> " /f "
		ModT  	-> " % "
		PowT  	-> " ^ "
		AndT  	-> " and "
		OrT   	-> " or "
		LArray 	-> " []= "
		RArray 	-> " =[] "

instance Binary BinOp where
	put AddI 	= putWord8 18
	put AddF 	= putWord8 19
	put SubI 	= putWord8 20
	put SubF 	= putWord8 21
	put MulI 	= putWord8 22
	put MulF 	= putWord8 23
	put DivI 	= putWord8 24
	put DivF 	= putWord8 25
	put ModT 	= putWord8 26
	put PowT 	= putWord8 27
	put AndT 	= putWord8 28
	put OrT 	= putWord8 29
	put LArray 	= putWord8 44
	put RArray	= putWord8 45
	

	get = do 
		w <- getWord8
		case w of 
			18 -> return AddI
			19 -> return AddF
			20 -> return SubI
			21 -> return SubF
			22 -> return MulI
			23 -> return MulF
			24 -> return DivI
			25 -> return DivF
			26 -> return ModT
			27 -> return PowT
			28 -> return AndT
			29 -> return OrT
			44 -> return LArray
			45 -> return RArray

data UnOp =
	NotT
	| NegI
	| NegF
	| LPoint
	| RPoint
	deriving(Eq)

instance Show UnOp where
	show a = case a of
		NotT  	-> "not"
		NegI 	-> "-i"
		NegF 	-> "-f"
		LPoint 	-> "*="
		RPoint 	-> "=*"

instance Binary UnOp where
	put NotT 	= putWord8 30
	put NegI 	= putWord8 31
	put NegF 	= putWord8 32
	put LPoint	= putWord8 46
	put RPoint	= putWord8 47

	get = do 
		w <- getWord8
		case w of 
			30 -> return NotT
			31 -> return NegI
			32 -> return NegF
			46 -> return LPoint
			47 -> return RPoint

data Relation = 
	Eq
	| GtT 
	| LtT
	| Ne 
	| Ge
	| Le 
	deriving(Eq)

instance Show Relation where
	show a = case a of
		Eq -> "=="
		GtT -> ">"
		LtT -> "<"
		Ne -> "!="
		Ge -> ">="
		Le -> "<="

instance Binary Relation where
	put Eq = putWord8 33
	put GtT = putWord8 34
	put LtT = putWord8 35
	put Ne = putWord8 36
	put Ge = putWord8 37
	put Le = putWord8 38

	get = do 
		w <- getWord8
		case w of 
			33 -> return Eq
			34 -> return GtT
			35 -> return LtT
			36 -> return Ne
			37 -> return Ge
			38 -> return Le		

newLabel :: Int -> Label
newLabel i = Label ('L':show i)

newTemp :: Int -> Reference
newTemp i = (Temp i)

patch :: Ins -> Label -> Ins
patch (Goto Nothing) l 				= Goto (Just l)
patch (IfGoto 	r0 r1 r2 Nothing) l = IfGoto r0 r1 r2 (Just l)
patch i _ 							= i 

showJ :: (Maybe Label) -> String
showJ (Nothing) = "_"
showJ (Just i) 	= show i

showR :: (Maybe Reference) -> String
showR (Nothing) = ""
showR (Just r) 	= show r


writeTac :: FilePath -> TAC -> IO()
writeTac = encodeFile

readTac :: FilePath -> IO(TAC)
readTac fp = 
	do 	res <- decodeFile fp
		Prelude.putStrLn (unlines $ Prelude.map show (FB.toList res))
		return res