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
	, Expression(..)
    , Operator (..)
    , Instructions(..)
	, AST(..)
	, treeExp
	, treeAST
	, treeIns
	, filterI
	, filterE
	, filterIns
	) where

import Tokens
import Lexeme
import Data.Tree
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
		| FuncT 	Type [Type]	AST
		| ProcT 	Type [Type]	AST
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
		 	FuncT t	l ast	-> "Function "  ++ show t ++ show (reverse l) ++ "\n" ++ drawTree (treeAST (filterI ast))
		 	ProcT t l ast 	-> "Procedure " ++ show t ++ show (reverse l) ++ "\n" ++ drawTree (treeAST (filterI ast))
		 	ArrayT d t 		-> "Array of "  ++ show t 
		 	TypeT s 		-> "TypeT " ++ s ++ " "
		 	TypeError 		-> "TypeError"


-- convierten lexemas en tipos del lenguaje
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
	TokenProc		-> ProcT bt lt (AST [])
	TokenFunc		-> FuncT bt lt (AST [])

makePointer :: Int -> Type -> Type 
makePointer 0 ty 	= ty
makePointer n ty 	= PointerT t
		where t 	= makePointer (n-1) ty

makeArray :: [Lexeme Token] -> Type -> Type
makeArray [] ty 	= ty
makeArray ((Lexeme (TokenInt d) _):ds) ty 	= ArrayT d t
		where t = makeArray ds ty


-- bitacora de errores de parsing 
type Binnacle = Either String String		

-- calcula el tamaño de un objeto
typeSize :: Type -> Int
typeSize IntT 			= 4
typeSize FloatT 		= 4
typeSize BoolT 			= 2
typeSize StringT  		= 4
typeSize CharT 			= 2
typeSize (PointerT _) 	= 4
typeSize IteratorT 		= 4
typeSize (FuncT t _ _) 	= typeSize t
typeSize (ProcT t _ _) 	= typeSize t
typeSize VoidT 			= 0
typeSize TypeError 		= 0

-- calculo del padding de un objeto
padding :: Type -> Int -> Int
padding (ArrayT d t) i 			= padding t i
padding (StructT m) i  			= padStruct i
padding (UnionT m) i   			= padStruct i
padding (TypeT s) i 			= padStruct i
padding (FuncT (TypeT s) _ _) i = padStruct i
padding (ProcT (TypeT s) _ _) i = padStruct i
padding t i 					= i + (i `mod` (typeSize t))

padStruct :: Int -> Int
padStruct i = i + (i `mod` 4)

suma :: Int -> Type -> Int
suma n t = n + typeSize t

-- tipo de dato que representa una entrada en la tabla de simbolos
data Entry = Entry Type Position Int Int deriving(Eq)
instance Show Entry where
    show (Entry t p s o) = show t ++ " " ++ show p ++ " Size : " ++ show s ++ " Offset: " ++ show o  


-- Hacer funcion del maximo tamaño para el padding de los structs
-- o meter todo en un mapa para luego calcular el maximo
-- funciones y tipos (structs) no tienen offset solo tamaño

data Expression 
    = BoolL     Bool        Position
    | IntL      Int         Position
    | FloatL    Float       Position
    | CharL     Char        Position
    | StringL   String      Position
    | VoidL     Position
    | IdL       String      Entry           Position 
    | ExpBin    Operator    Expression      Expression Position
    | ExpUna    Operator    Expression      Position
    | Index     Expression  [Expression]    Position
    | FCall     Expression  [Expression]    Position
    | CFCall    Expression  Expression      Position
    | AccsA     Expression  [Expression]    Position
    | AccsS     Expression  [Expression]    Position
    | AccsP     Expression  Int Position
    | NoneE
    deriving(Show, Eq)

data Operator 
    = Plus 
    | Minus
    | Mul 
    | Slash 
    | Div
    | Mod 
    | Power 
    | Arrow
    | Gt
    | Lt
    | GEt
    | LEt
    | Equal
    | Inequal
    | And 
    | Or 
    | Not
    deriving(Eq)

instance Show Operator where 
    show Plus       = "+"
    show Minus      = "-"
    show Mul        = "*"
    show Slash      = "/"
    show Div        = "div"
    show Mod        = "mod"
    show Power      = "^"
    show Arrow      = "->"
    show Gt         = ">"
    show Lt         = "<"
    show GEt        = ">="
    show LEt        = "<="
    show Equal      = "=="
    show Inequal    = "/="
    show And        = "and"
    show Or         = "or"
    show Not        = "not"

data Instructions
	= IfL 		Expression 		[Instructions]  Position
	| IfteL		Expression 		[Instructions]  [Instructions]  Position
	| ForL 		Expression 		Expression 		Expression		[Instructions]	Position
	| WhileL 	Expression 		[Instructions]	Position
	| RepeatL 	[Instructions] 	Expression		Position
	| ReadL 	Expression		Position
	| WriteL	Expression 		Position
	| ReturnL 	Expression		Position
	| AsngL 	Expression 		Expression		Position
	| FreeL 	Expression		Position
	| None
	| DecL 
	deriving(Show, Eq)

data AST = AST [Instructions] deriving (Eq, Show)

--newtype Nodo = AST | Instructions | Expression 

treeAST :: AST -> Tree String
treeAST (AST is) = Node "AST" (map treeIns is)

treeIns :: Instructions -> Tree String
treeIns (IfL exp is p) 
	= Node ("IF " ++ show p) ((treeExp exp): map treeIns (reverse is))
treeIns (IfteL exp ist ise p) 
	= Node ("IF-Then-Else " ++ show p) ((treeExp exp):map treeIns (reverse ist) ++ map treeIns (reverse ise))
treeIns (ForL exp1 exp2 exp3 is p) 
	= Node ("For " ++ show p) ((treeExp exp1):(treeExp exp2):(treeExp exp3):map treeIns (reverse is))
treeIns (WhileL exp is p) 
	= Node ("While " ++ show p) ((treeExp exp):map treeIns (reverse is))
treeIns (RepeatL is exp p) 
	= Node ("Repeat " ++ show p) ((treeExp exp):map treeIns (reverse is))
treeIns (ReadL exp p) 
	= Node ("Read " ++ show p) [treeExp exp]
treeIns (WriteL exp p) 
	= Node ("Write " ++ show p) [treeExp exp]
treeIns (ReturnL exp p) 
	= Node ("Return " ++ show p) [treeExp exp]
treeIns (AsngL exp1 exp2 p) 
	= Node ("Assignation " ++ show p) [treeExp exp1, treeExp exp2]
treeIns (FreeL exp p) 
	= Node ("Free " ++ show p) [treeExp exp]
treeIns None = Node "" []
treeIns DecL = Node "" []

treeExp :: Expression -> Tree String
treeExp (BoolL b p) = Node ("Bool " ++ show p) [Node (show b) []]
treeExp (IntL i p) = Node ("Int " ++ show p) [Node (show i) []]
treeExp (FloatL f p) = Node ("Float " ++ show p) [Node (show f) []]
treeExp (CharL c p) = Node ("Char " ++ show p) [Node (show c) []]
treeExp (StringL s p) = Node ("String " ++ show p) [Node (show s) []]
treeExp (VoidL p) = Node ("Void " ++ show p) []
treeExp (IdL s e p) = Node ("Variable " ++ show p ++ show e) [Node (show s) []]
treeExp (ExpBin op exp1 exp2 p) 
	= Node ("ExpBin: " ++ show op ++ " " ++ show p) [treeExp exp1, treeExp exp2]
treeExp (ExpUna op exp p) 
	= Node ("ExpUn: " ++ show op ++ " " ++ show p) [treeExp exp]
treeExp (FCall e es p)    -- Era lo que estaba al revez y no se si sea lo mejor poner una variable.
	= Node ("Function " ++ show p) ((treeExp e):map treeExp (reverse es)) 
treeExp (CFCall exp1 exp2 p) 
	= Node ("Function " ++ show p) [treeExp exp1,treeExp exp2] -- No estoy seguro si esta bien
treeExp (AccsA e es p) 
	= Node ("Array " ++ show p) ((treeExp e):map treeExp (reverse es)) -- Era lo que estaba al revez
treeExp (AccsS e es p) 
	= Node ("Accesor " ++ show p) ((treeExp e):map treeExp es)
treeExp (AccsP e 1 p) 
	= Node ("Accesor " ++ show p) [treeExp e]
treeExp (AccsP e i p) 
	= Node ("Accesor " ++ show p) [treeExp (AccsP e (i-1) p)]

filterI :: AST -> AST
filterI (AST is) = AST (filter (/= DecL) is)

filterIns :: [Instructions] -> [Instructions]
filterIns l = filter (/= DecL) l

filterE :: [Expression] -> [Expression]
filterE le = filter (/= NoneE) le

