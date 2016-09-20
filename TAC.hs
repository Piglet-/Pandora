module TAC where

import qualified Data.Sequence as DS
import System.IO 
import Control.Monad

data TAC = TAC (DS.Seq Ins)
	deriving(Eq,Show,Read) 

data Ins =  
	Comment String
	| AssingB 
		{ 	result :: Reference,
			binop :: BinOp,
			left :: Reference,
			right :: Reference
		}
	| AssingU
		{ 	result :: Reference,
			unop :: BinOp,
			ope :: Reference
		}
	| Assing 
		{	lv :: Reference,
			rv :: Reference
		}
	| Goto 		(Maybe Label)
	| IfGoto 	Relation Reference Reference (Maybe Label)
	| IfTrueGt	Reference (Maybe Label)
	| IfFalseGt	Reference (Maybe Label)
	deriving (Eq,Read)

instance Show Ins where
	show a = case a of
		Comment s -> "# " ++ (show s)
		AssingB re o l r -> (show re) ++ " := " ++ (show l) ++ (show o) ++ (show r)
		AssingU r o op -> (show r) ++ ":= " ++ (show o) ++ (show op)
		Assing l r -> (show l) ++ ":= " ++ (show r)

newtype Label = Label String deriving (Eq, Show, Read)

data Reference = 
	Address String Reference
	| Constant Value
	| Temp Int 
	deriving(Eq, Read)

instance Show Reference where
	show a = case a of
		Address s r 	-> s ++ (show r)
		Constant v  	-> "Cons " ++ (show v)
		Temp i 		-> "Temp" ++ (show i)

data Value =
	ValInt 		Int
	| ValFloat 	Float
	| ValChar	Char 
	| ValBool	Bool 
	| ValString String
	deriving(Eq, Read)

instance Show Value where
	show a = case a of
		ValInt i 		-> show i 
		ValFloat f 	-> show f
		ValChar c 		-> show c
		ValBool b 		-> show b
		ValString s	-> show s 

data BinOp =
	Add 
	| Sub
	| Mul 
	| DivI 
	| DivF 
	| Mod 
	| Pow
	| And 
	| Or
	deriving (Eq, Show,Read)

data UnOp =
	Not
	| Neg
	deriving(Eq, Show, Read)

data Relation = 
	Eq
	| Gt 
	| Lt
	| Ne 
	| Ge
	| Le 
	deriving(Eq, Show, Read)

writeF :: TAC -> IO()
writeF cont = do
	writeFile "test.txt" (show cont)

tac = TAC (DS.empty DS.|> (Assing (Temp 1) (Constant (ValInt 3))))

--main = do
--	writeF tac

main = do 
	cont <- readFile "test1.txt"
	writeF (read $ cont)