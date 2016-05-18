module Type
	( 
	Type (..)
	, Binnacle(..)
	, makeBtype
	, makeObj
	) where

import Tokens
import Lexeme

data Type = IntT
		| FloatT 
		| BoolT
		| CharT	
		| PointerT
		| VoidT
		| StructT
		| UnionT
		| StringT
		| IteratorT
		| FuncT Type	
		| ProcT Type	
		| ArrayT Type
		deriving(Eq)

instance Show Type where
	show t = 
		case t of
			IntT         	-> "Int"
			FloatT 			-> "Float"
		 	BoolT 			-> "Bool"
		 	CharT			-> "Char"
		 	PointerT		-> "Pointer"
		 	VoidT 			-> "Void"
		 	StructT 		-> "Struct"
		 	UnionT 			-> "Union"
		 	StringT 		-> "String"
		 	IteratorT 		-> "Iterator"
		 	FuncT t			-> "Function "  ++ show t
		 	ProcT t 	 	-> "Procedure " ++ show t 
		 	ArrayT t 		-> "Array "  	++ show t

makeBtype :: Lexeme t -> Type
makeBtype l = case (token l) of
	TokenIntT 		-> IntT
	TokenFloatT 	-> FloatT
	TokenBoolT 		-> BoolT
	TokenCharT 		-> CharT
	TokenStringT 	-> StringT
	TokenVoid 		-> VoidT
	TokenStruct 	-> StructT
	TokenUnion 		-> UnionT
	TokenNew 		-> PointerT

makeObj :: Lexeme t -> Type -> Type
makeObj l bt = case (token l) of
	TokenArray 		-> ArrayT bt
	TokenProc		-> ProcT bt
	TokenFunc		-> FuncT bt

type Binnacle = Either String String
