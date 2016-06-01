module Type
	( 
	Type (..)
	, Binnacle(..)
	, makeBtype
	, makeObj
	, makeStruct
	, makePointer
	, makeArray
	) where

import Tokens
import Lexeme

data Type = IntT
		| FloatT 
		| BoolT
		| CharT	
		| PointerT Type
		| VoidT
		| StructT [(Lexeme Token, Type)]
		| UnionT [(Lexeme Token, Type)]
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
		 	PointerT t		-> "Pointer" ++ show t
		 	VoidT 			-> "Void"
		 	StructT l		-> "Struct" ++ show l
		 	UnionT 	l		-> "Union" 	++ show l
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

makeStruct :: Lexeme t -> [(Lexeme Token, Type)] -> Type
makeStruct lex list = case (token lex) of
	TokenStruct -> StructT list
	TokenUnion	-> UnionT list


makeObj :: Lexeme t -> Type -> Type
makeObj l bt = case (token l) of
	TokenProc		-> ProcT bt
	TokenFunc		-> FuncT bt

makePointer :: Int -> Type -> Type 
makePointer 0 ty = ty
makePointer n ty = PointerT t
		where t = makePointer (n-1) ty

makeArray :: Int -> Type -> Type
makeArray 0 ty = ty
makeArray n ty = ArrayT t
		where t = makeArray (n-1) ty


type Binnacle = Either String String

