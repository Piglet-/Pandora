module Symbol_Table
    ( Symbol_Table(..)
    , focus
    , lookupS
    , lookupS'
    , empty_ST
    , goDown
    , goBack
    , insertT
    , insertS
    , tothetop
    , Zipper	
    ) where

import qualified Data.Map.Strict as DMap
import qualified Data.Sequence   as DS
import Data.Foldable (toList)
import Data.Maybe (fromJust)

-- tipo de datos para la tabla de simbolos
data Symbol_Table = Symbol_Table Int (DMap.Map String String) (DS.Seq (Symbol_Table)) 

-- instancia show de la tabla de simbolos
instance Show Symbol_Table where
    show st = "\nSymbol Table: \n\n" ++ showTable st

-- mestra las tablas con identacion
showTable :: Symbol_Table -> String
showTable (Symbol_Table t maps childrens) = 
    (tabs t) ++ "Level: " ++ show t ++ "\n" ++
    (tabs t) ++ "Scope:\n" ++
    (showHash maps t) ++ concat (toList (fmap showTable (DS.reverse childrens))) 
        where tabs t = concat $ replicate t "\t"

-- muestra los elementos internos de la tabla
showHash :: (DMap.Map String String) -> Int -> String
showHash m t = showListC (DMap.keys m) t

showListC :: [String] -> Int -> String
showListC [] _ = ""
showListC (x:xs) t = (concat $ replicate t "\t") ++ 
				show x ++ "\n" ++ showListC xs t

-- tipo de datos del camino
data Breadcrumbs = 
    Breadcrumbs Int (DMap.Map String String) (DS.Seq (Symbol_Table)) (DS.Seq (Symbol_Table)) 
        deriving (Show) 

-- zipper que modela una tabla de simbolos y el camino
type Zipper = (Symbol_Table, [Breadcrumbs]) 

-- entrar en una tabla de simbolos
goDown :: Zipper -> Maybe Zipper
goDown (Symbol_Table i f sts, bs) = 
    if DS.null sts 
        then Nothing
        else Just (fcs, (Breadcrumbs i f DS.empty st): bs)
            where fcs DS.:< st = DS.viewl sts

-- regresar a la tabla anterior
goBack :: Zipper -> Maybe (Zipper)
goBack (fcs, []) = Nothing
goBack (st, (Breadcrumbs i p ls rs): bs) = Just (Symbol_Table i p ((ls DS.|> st) DS.>< rs) , bs)

-- ir a la tabla principal
tothetop :: Zipper -> Zipper
tothetop (fcs, []) = (fcs, []) 
tothetop bc = tothetop $ fromJust (goBack bc)

-- busca el simbolo en toda la tabla
lookupS :: String -> Zipper -> Maybe (String, Int) 
lookupS k (Symbol_Table i m sts, bs) = 
                case DMap.lookup k m of
                        Nothing -> if null bs 
                                    then Nothing
                                    else lookupS k $ fromJust $ goBack (Symbol_Table i m sts, bs)
                        Just v  -> Just (v, i)

-- busca el simbolo solo en el alcace actual
lookupS' :: String -> Zipper -> Maybe String
lookupS' k (Symbol_Table i m sts, bs) = DMap.lookup k m 

-- inserta un nuevo simbolo
insertS :: String -> String -> Zipper -> Zipper 
insertS k v (Symbol_Table i m sts, bs) = (Symbol_Table i (DMap.insert k v m) sts, bs) 

-- inserta una nueva tabla
insertT :: Zipper -> Zipper
insertT (Symbol_Table i m sts, bs) = (Symbol_Table i m (st DS.<| sts), bs)
	where st = (Symbol_Table (succ i) DMap.empty (DS.empty))

-- coloca una tabla en el zipper
focus :: Symbol_Table -> Zipper
focus st = (st, [])

-- devuelve la tabla de un zipper
defocus :: Zipper -> Symbol_Table 
defocus (st, bs) = st  

-- inicia una tabla como vacia
empty_ST :: Int -> Symbol_Table 
empty_ST i = Symbol_Table i (DMap.empty) (DS.empty)
