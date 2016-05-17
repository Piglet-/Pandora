module SymbolTable
    ( SymbolTable(..)
    , focus
    , defocus
    , lookupS
    , lookupS'
    , emptyST
    , goDown
    , goBack
    , insertT
    , insertS
    , tothetop
    , Zipper
    , Entry(..)
    , Scope(..)
    , emptyScope
    ) where

import Position
import qualified Data.Map.Strict as DMap
import qualified Data.Sequence   as DS
import Data.Foldable (toList)
import Data.Maybe (fromJust)

-- una entrada (o valor en un hash) es el tipo (en string)
-- y la posición de una variable dentro de la tabla de símbolos
data Entry = Entry String Position deriving (Show)

-- un scope es un entero que representa el nivel de anidamiento,
-- y una tupla con la posicion inicial y final del scope
data Scope = Scope Int (Position, Position) deriving(Show)

-- tipo de datos para la tabla de simbolos

data SymbolTable = SymbolTable Scope (DMap.Map String Entry) (DS.Seq (SymbolTable)) 


-- instancia show de la tabla de simbolos
instance Show SymbolTable where
    show st = "\nSymbol Table: \n\n" ++ showTable st

-- mestra las tablas con identacion
showTable :: SymbolTable -> String
showTable (SymbolTable (Scope t s) maps childrens) = 
    (tabs t) ++ "Level: " ++ show t ++ "\n" ++
    (tabs t) ++ "Scope:\n" ++
    (showHash maps t) ++ concat (toList (fmap showTable (DS.reverse childrens))) 
        where tabs t = concat $ replicate t "\t"

-- muestra los elementos internos de la tabla
showHash :: (DMap.Map String Entry) -> Int -> String
showHash m t = showListC (DMap.keys m) t

showListC :: [String] -> Int -> String
showListC [] _ = ""
showListC (x:xs) t = (concat $ replicate t "\t") ++ 
				show x ++ "\n" ++ showListC xs t

-- tipo de datos del camino
data Breadcrumbs = 
    Breadcrumbs Scope (DMap.Map String Entry) (DS.Seq (SymbolTable)) (DS.Seq (SymbolTable)) 
        deriving (Show) 

-- zipper que modela una tabla de simbolos y el camino
type Zipper = (SymbolTable, [Breadcrumbs]) 

-- entrar en una tabla de simbolos
goDown :: Zipper -> Maybe Zipper
goDown (SymbolTable i f sts, bs) = 
    if DS.null sts 
        then Nothing
        else Just (fcs, (Breadcrumbs i f DS.empty st): bs)
            where fcs DS.:< st = DS.viewl sts

-- regresar a la tabla anterior
goBack :: Zipper -> Maybe (Zipper)
goBack (fcs, []) = Nothing
goBack (st, (Breadcrumbs i p ls rs): bs) = Just (SymbolTable i p ((ls DS.|> st) DS.>< rs) , bs)

-- ir a la tabla principal
tothetop :: Zipper -> Zipper
tothetop (fcs, []) = (fcs, []) 
tothetop bc = tothetop $ fromJust (goBack bc)

-- busca el simbolo en toda la tabla
lookupS :: String -> Zipper -> Maybe (Entry, Scope) -- No se si es bueno devolver el  
lookupS k (SymbolTable i m sts, bs) =                -- scope o el entero
                case DMap.lookup k m of
                        Nothing -> if null bs 
                                    then Nothing
                                    else lookupS k $ fromJust $ goBack (SymbolTable i m sts, bs)
                        Just v  -> Just (v, i)

-- busca el simbolo solo en el alcace actual
lookupS' :: String -> Zipper -> Maybe Entry
lookupS' k (SymbolTable i m sts, bs) = DMap.lookup k m 

-- inserta un nuevo simbolo
insertS :: String -> Entry -> Zipper -> Zipper 
insertS k v (SymbolTable i m sts, bs) = (SymbolTable i (DMap.insert k v m) sts, bs) 

-- inserta una nueva tabla
insertT :: Zipper -> Zipper
insertT (SymbolTable (Scope i p) m sts, bs) = (SymbolTable (Scope i p) m (st DS.<| sts), bs)
	where st = (SymbolTable (Scope (succ i) p) DMap.empty (DS.empty))

-- coloca una tabla en el zipper
focus :: SymbolTable -> Zipper
focus st = (st, [])

-- devuelve la tabla de un zipper
defocus :: Zipper -> SymbolTable 
defocus (st, bs) = st  

-- inicia una tabla como vacia
emptyST :: Scope -> SymbolTable 
emptyST i = SymbolTable i (DMap.empty) (DS.empty)

-- habrir un nuevo alcance
openScope:: Zipper -> Zipper
openScope z = fromJust $ goDown $ insertT z

-- cerrar el alcance actual, si no se puede porque es root
-- no hace nada.. debería dar un error??
closeScope :: Zipper -> Zipper
closeScope z = maybe z id (goBack z)

emptyScope :: Scope
emptyScope = Scope 0 (Position (0,0), Position (0,0))