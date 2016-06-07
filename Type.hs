module Type
	( 
	Type (..)
	,ClassType (..)
	, Binnacle(..)
	, makeBtype
	, makeObj
	, makeStruct
	, makePointer
	, makeArray
	) where

import Tokens
import Lexeme

data ClassType = Variable Type
				| Field	  Type
				| Ctype   Type -- nuevos tipos (structs, unions)


data Type = IntT
		| FloatT 
		| BoolT
		| CharT	
		| PointerT Type
		| VoidT
		| StructT [(String, Type)] 
		| UnionT [(String, Type)]
		| StringT
		| IteratorT
		| FuncT Type [Type]	
		| ProcT Type [Type]	
		| ArrayT Type 
		| TypeT String 
		deriving(Eq)

instance Show Type where
	show t = 
		case t of
			IntT         	-> "Int "
			FloatT 			-> "Float "
		 	BoolT 			-> "Bool "
		 	CharT			-> "Char "
		 	PointerT t		-> "Pointer to " ++ show t
		 	VoidT 			-> "Void "
		 	StructT l		-> "Struct " ++ show l
		 	UnionT 	l		-> "Union " ++ show l
		 	StringT 		-> "String "
		 	IteratorT 		-> "Iterator "
		 	FuncT t	l		-> "Function "  ++ show t ++ show l
		 	ProcT t l	 	-> "Procedure " ++ show t ++ show l
		 	ArrayT t 		-> "Array of " ++ show t 
		 	TypeT s 		-> "TypeT " ++ s

makeBtype :: Lexeme t -> Type
makeBtype l = case (token l) of
	TokenIntT 		-> IntT
	TokenFloatT 	-> FloatT
	TokenBoolT 		-> BoolT
	TokenCharT 		-> CharT
	TokenStringT 	-> StringT
	TokenVoid 		-> VoidT
	TokenIdent s    -> TypeT s

makeStruct :: Lexeme t -> [(Lexeme Token, Type)] -> Type
makeStruct lex list = case (token lex) of
	TokenStruct -> StructT (aux list)
	TokenUnion	-> UnionT (aux list)

aux :: [(Lexeme Token, Type)] -> [(String, Type)]
aux [] = []
aux (((Lexeme (TokenIdent s) _),t):ls) =  (s,t):(aux ls)


makeObj :: Lexeme t -> Type -> [Type]-> Type
makeObj l bt lt = case (token l) of
	TokenProc		-> ProcT bt lt
	TokenFunc		-> FuncT bt lt

makePointer :: Int -> Type -> Type 
makePointer 0 ty = ty
makePointer n ty = PointerT t
		where t = makePointer (n-1) ty

makeArray :: Int -> Type -> Type
makeArray 0 ty = ty
makeArray n ty = ArrayT t
		where t = makeArray (n-1) ty


type Binnacle = Either String String

