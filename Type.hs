module Type
	( 
	Type (..)
	, Binnacle(..)
	, makeBtype
	, makeObj
	, makePointer
	, makeArray
	, typeSize
	, padding
	, padStruct
	, Entry(..)
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
		| StructT 	(DMap.Map String Entry) 
		| UnionT 	(DMap.Map String Entry)
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
		 	ArrayT d t 		-> "Array of "  ++ show t 
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
typeSize IntT 			= 4
typeSize FloatT 		= 4
typeSize BoolT 			= 2
typeSize StringT  		= 4
typeSize CharT 			= 2
typeSize (PointerT _) 	= 4
typeSize IteratorT 		= 4
typeSize (FuncT t _) 	= typeSize t
typeSize (ProcT t _) 	= typeSize t
typeSize VoidT 			= 0
typeSize TypeError 		= 0

padding :: Type -> Int -> Int
padding (ArrayT d t) i 	= padding t i
padding (StructT m) i  	= padStruct i
padding (UnionT m) i   	= padStruct i
padding (TypeT s) i 	= padStruct i
padding t i = i + (i `mod` (typeSize t))

padStruct :: Int -> Int
padStruct i = i + (i `mod` 4)

suma :: Int -> Type -> Int
suma n t = n + typeSize t

data Entry = Entry Type Position Int Int deriving(Eq)
instance Show Entry where
    show (Entry t p s o) = show t ++ " " ++ show p ++ " Size : " ++ show s ++ " Offset: " ++ show o  
