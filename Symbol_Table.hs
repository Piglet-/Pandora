module Symbol_Table
    ( Symbol_Table(..)
    , focus
    , lookupS
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

data Symbol_Table = Symbol_Table Int (DMap.Map String String) (DS.Seq (Symbol_Table)) 
    
instance Show Symbol_Table where
    show st = "Symbol Table: \n" ++ showTable st

showTable :: Symbol_Table -> String
showTable (Symbol_Table t maps childrens) = 
    (tabs t) ++ "Scope: " ++ show t ++ "\n" ++
    (tabs t) ++ show (DMap.keys maps) ++ "\n" ++ concat (toList (fmap showTable childrens)) 
        where tabs t = concat $ replicate t "\t"


data Breadcrumbs = 
    Breadcrumbs Int (DMap.Map String String) (DS.Seq (Symbol_Table)) (DS.Seq (Symbol_Table)) 
        deriving (Show) 
type Zipper = (Symbol_Table, [Breadcrumbs]) 

goDown :: Zipper -> Maybe Zipper
goDown (Symbol_Table i f sts, bs) = 
    if DS.null sts 
        then Nothing
        else Just (fcs, (Breadcrumbs i f DS.empty st): bs)
            where fcs DS.:< st = DS.viewl sts

goBack :: Zipper -> Maybe (Zipper)
goBack (fcs, []) = Nothing
goBack (st, (Breadcrumbs i p ls rs): bs) = Just (Symbol_Table i p ((ls DS.|> st) DS.>< rs) , bs)

goRight :: Zipper -> Maybe (Zipper)
goRight (_, []) = Nothing
goRight (fcs, (Breadcrumbs i p ls rs): bs) = 
    if DS.null rs 
        then Nothing
        else Just (r, (Breadcrumbs i p (ls DS.|> fcs) rrs): bs)
            where r DS.:< rrs = DS.viewl rs

goLeft :: Zipper-> Maybe (Zipper)
goLeft (_, []) = Nothing
goLeft (fcs, (Breadcrumbs i p ls rs): bs) = 
    if DS.null ls 
        then Nothing
        else Just (l, (Breadcrumbs i p lls (fcs DS.<| rs)): bs)
			where l DS.:< lls = DS.viewl ls

tothetop :: Zipper -> Zipper
tothetop (fcs, []) = (fcs, []) 
tothetop bc = tothetop $ fromJust (goBack bc)

lookupS :: String -> Zipper -> Maybe String 
lookupS k (Symbol_Table i m sts, bs) = 
                case DMap.lookup k m of
                        Nothing -> if null bs 
                                    then Nothing
                                    else lookupS k $ fromJust $ goBack (Symbol_Table i m sts, bs)
                        v       -> v

insertS :: String -> String -> Zipper -> Zipper 
insertS k v (Symbol_Table i m sts, bs) = (Symbol_Table i (DMap.insert k v m) sts, bs) 


insertT :: Zipper -> Zipper
insertT (Symbol_Table i m sts, bs) = (Symbol_Table i m (st DS.<| sts), bs)
	where st = (Symbol_Table (succ i) DMap.empty (DS.empty))

focus :: Symbol_Table -> Zipper
focus st = (st, [])

defocus :: Zipper -> Symbol_Table 
defocus (st, bs) = st  

empty_ST :: Int -> Symbol_Table 
empty_ST i = Symbol_Table i (DMap.empty) (DS.empty)
