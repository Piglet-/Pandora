module TAC 
	( TAC (..)
	, Label (..)
	, Reference (..)
	, Value (..)
	, Ins (..)
	, BinOp (..)
	, UnOp (..)
	) where

import qualified Data.Sequence as DS
import qualified Data.Foldable as FB
import Data.Binary as Bin
import Control.Monad 

type TAC = DS.Seq Ins

data Ins =  
	Comment 	String
	| AssignB 	BinOp Reference Reference Reference
	| AssignU 	UnOp Reference Reference
	| Assign 	Reference Reference
	| Goto 		(Maybe Label)
	| IfGoto 	Relation Reference Reference (Maybe Label)
	| IfNotGoto	Relation Reference Reference (Maybe Label)
	| Param 	Reference
	| Call 		Reference String Int 
	| CallP		String Int
	| Return 	(Maybe Reference)
	| PrintT	Reference
	deriving (Eq)

instance Show Ins where
	show a = case a of
		Comment s 			-> "# " ++ s
		AssignB o re l r 	-> (show re) ++ " := " ++ (show l) ++ (show o) ++ (show r)
		AssignU o r  op 	-> (show r) ++ " := " ++ (show o) ++ (show op)
		Assign 	l r 		-> (show l) ++ " := " ++ (show r)
		Goto 	l 			-> "Goto " ++  showJ l
		IfGoto	o r1 r2	l	-> "If " ++ show r1 ++ " " ++ show o ++ " " ++ show r2 ++ " Goto " ++ showJ l
		IfNotGoto o r1 r2 l	-> "If not " ++  show r1 ++ " " ++ show o ++ " " ++ show r2 ++ " Goto " ++ showJ l
		Param r 			-> "Param " ++ show r
		Call r s i			-> show r ++ " := " ++ "call " ++ s ++ "," ++ show i 
		CallP s i 			-> "call " ++ s ++ "," ++ show i 
		Return r 			-> "Return " ++ showR r
		PrintT r 			-> "Print " ++ show r 

instance Binary Ins where
	put (Comment s) 			= putWord8 0 >> put s
	put (AssignB re o l r) 		= putWord8 1 >> put re >> put o >> put l >> put r
	put (AssignU r o op) 		= putWord8 2 >> put r >> put o >> put op
	put (Assign l r) 			= putWord8 3 >> put l >> put r
	put (Goto 	l)	 			= putWord8 4 >> put l
	put (IfGoto	o r1 r2	l) 		= putWord8 5 >> put o >> put r1 >> put r2 >> put l
	put (IfNotGoto o r1 r2 l) 	= putWord8 43 >> put o >> put r1 >> put r2 >> put l
	put (Param r)				= putWord8 39 >> put r
	put (Call r s i) 			= putWord8 8 >> put r >> put s >> put i
	put (CallP s i)				= putWord8 41 >> put s >> put i
	put (Return r)				= putWord8 42 >> put r 
	put (PrintT r) 				= putWord8 9 >> put r

	get = do 
		    w <- getWord8
		    case w of
		       	0  ->  Bin.get >>= return . Comment
		       	1  ->  makeT4 AssignB
		       	2  ->  makeT3 AssignU
		       	3  ->  makeT2  Assign
		       	4  ->  Bin.get >>= return .  Goto
		    	5  ->  makeT4 IfGoto
		    	43 ->  makeT4 IfNotGoto
		    	8  ->  makeT3 Call
		    	41 ->  makeT2 CallP
		    	39 ->  Bin.get >>= return . Param
		    	42 ->  Bin.get >>= return . Return
		    	9  ->  Bin.get >>= return . PrintT 

makeT2::(Binary a1, Binary a2) => (a1 -> a2 -> r) -> Get r
makeT2 t = liftM2 t Bin.get Bin.get

makeT3::(Binary a1, Binary a2, Binary a3) => (a1 -> a2 -> a3 -> r) -> Get r
makeT3 t = liftM3 t Bin.get Bin.get Bin.get

makeT4::(Binary a1, Binary a2, Binary a3, Binary a4) => (a1 -> a2 -> a3 -> a4 -> r) -> Get r
makeT4 t = liftM4 t Bin.get Bin.get Bin.get Bin.get


newtype Label = Label Int deriving (Eq)

instance Show Label where
	show (Label i) = "L" ++ show i

instance Binary Label where
	put (Label l) = put l
	get = do Bin.get >>= return . Label 

data Reference = 
	Address 	String Reference
	| Constant 	Value
	| Temp 		Int
	deriving(Eq)

instance Show Reference where
	show a = case a of
		Address 	s r 	-> s ++ " " ++ show r
		Constant 	v  		-> show v
		Temp 		i 		-> "T" ++ show i

instance Binary Reference where
	put (Address s r ) 	= putWord8 10 >> put s >> put r
	put (Constant v) 	= putWord8 11 >> put v
	put (Temp i) 		= putWord8 12 >> put i

	get = do 
		w <- getWord8
		case w of
			10  -> makeT2 Address
			11 	-> Bin.get >>= return . Constant
			12	-> Bin.get >>= return . Temp

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
	put OrT 		= putWord8 29
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
	| Gt 
	| Lt
	| Ne 
	| Ge
	| Le 
	deriving(Eq)

instance Show Relation where
	show a = case a of
		Eq -> "=="
		Gt -> ">"
		Lt -> "<"
		Ne -> "!="
		Ge -> ">="
		Le -> "<="

instance Binary Relation where
	put Eq = putWord8 33
	put Gt = putWord8 34
	put Lt = putWord8 35
	put Ne = putWord8 36
	put Ge = putWord8 37
	put Le = putWord8 38

	get = do 
		w <- getWord8
		case w of 
			33 -> return Eq
			34 -> return Gt
			35 -> return Lt
			36 -> return Ne
			37 -> return Ge
			38 -> return Le		

newLabel :: Int -> Label
newLabel i = (Label i)

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


tac = DS.fromList [(Assign (Temp 1) (Constant (ValInt 3))), 
		(IfGoto (Gt) (Constant (ValInt 2)) (Constant (ValInt 5)) (Just (Label 1))),
		(Comment "Hola Mundo!"),
		(Call (Constant (ValString "qux")) "bar" 3),
		(CallP "baz" 2)]

writeTac :: FilePath -> TAC -> IO()
writeTac = encodeFile

readTac :: FilePath -> IO(TAC)
readTac fp = 
	do 	res <- decodeFile fp
		Prelude.putStrLn (unlines $ Prelude.map show (FB.toList res))
		return res