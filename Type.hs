module Type
	( 
	Type (..)
	, Binnacle(..)
	, makeBtype
	, makeObj
	, makeStruct
	, makePointer
	, makeArray
	, typeSize
	) where

import Tokens
import Lexeme
import qualified Data.Map.Strict as DMap

data Type = IntT
		| FloatT 
		| BoolT
		| CharT	
		| PointerT 	Type
		| VoidT
		| StructT 	(DMap.Map String Type) 
		| UnionT 	(DMap.Map String Type)
		| StringT
		| IteratorT
		| FuncT 	Type [Type]	
		| ProcT 	Type [Type]	
		| ArrayT 	Int  Type 
		| TypeT 	String 
		| TypeError
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
		 	ArrayT d t 		-> "Array "  	++ show t 
		 	TypeT s 		-> "TypeT " ++ s ++ " "
		 	TypeError 		-> "TypeError"


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
	TokenStruct -> StructT 	(toMap list)
	TokenUnion	-> UnionT 	(toMap list)

aux :: [(Lexeme Token, Type)] -> [(String, Type)]
aux [] = []
aux (((Lexeme (TokenIdent s) _),t):ls) =  (s,t):(aux ls)

toMap :: [(Lexeme Token, Type)] -> DMap.Map String Type
toMap l = DMap.fromList (aux l)

makeObj :: Lexeme t -> Type -> [Type]-> Type
makeObj l bt lt = case (token l) of
	TokenProc		-> ProcT bt lt
	TokenFunc		-> FuncT bt lt

makePointer :: Int -> Type -> Type 
makePointer 0 ty 	= ty
makePointer n ty 	= PointerT t
		where t 	= makePointer (n-1) ty

makeArray :: [Lexeme Token] -> Type -> Type
makeArray [] ty 	= ty
makeArray ((Lexeme (TokenInt d) _):ds) ty 	= ArrayT d t
		where t = makeArray ds ty


type Binnacle = Either String String		

typeSize :: Type -> Int
typeSize IntT = 4
typeSize FloatT = 8
typeSize BoolT = 1
typeSize StringT  = 4
typeSize CharT = 2
typeSize (PointerT _) = 4
typeSize IteratorT = 4
typeSize (ArrayT d t) = d * typeSize t
typeSize (FuncT t _) = typeSize t
typeSize (ProcT t _) = typeSize t
typeSize VoidT = 0

suma :: Int -> Type -> Int
suma n t = n + typeSize t

-- METER VALORES EN LAS ASIGNACIONES