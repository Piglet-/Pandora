module Symbol_Table
    (Symbol_Table(..)
    ) where

import qualified Data.Map.Strict as DMap
import qualified Data.Sequence   as DS


data Symbol_Table a = Symbol_Table (DMap.Map String a) ( DS.Seq (Symbol_Table a)) deriving (Show)
data Breadcrumbs  a = 
    Breadcrumbs (DMap.Map String a)  ( DS.Seq (Symbol_Table a)) ( DS.Seq (Symbol_Table a)) deriving (Show) 
type Zipper a = (Symbol_Table a, [Breadcrumbs a]) 

goDown :: Zipper a -> Maybe (Zipper a)
goDown (Symbol_Table f sts, bs) = 
    if DS.null sts 
        then Nothing
        else Just (fcs, (Breadcrumbs f DS.empty st): bs)
            where fcs DS.:< st = DS.viewl sts


goBack :: Zipper a -> Zipper a
goBack (fcs, []) = (fcs, [])
goBack (st, (Breadcrumbs p ls rs): bs) = (Symbol_Table p ((ls DS.|> st) DS.>< rs) , bs)

goRight :: Zipper a -> Maybe (Zipper a)
goRight (_, []) = Nothing
goRight (fcs, (Breadcrumbs p ls rs): bs) = 
    if DS.null rs 
        then Nothing
        else Just (r, (Breadcrumbs p (ls DS.|> fcs) rrs): bs)
            where r DS.:< rrs = DS.viewl rs

goLeft :: Zipper a -> Maybe (Zipper a)
goLeft (_, []) = Nothing
goLeft (fcs, (Breadcrumbs p ls rs): bs) = 
    if DS.null ls 
        then Nothing
        else Just (l, (Breadcrumbs p lls (fcs DS.<| rs)): bs)
            where l DS.:< lls = DS.viewl ls

tothetop :: Zipper a -> Zipper a
tothetop (fcs, []) = (fcs, []) 
tothetop bc = tothetop $ goBack bc


lookupS :: String -> Zipper a -> Maybe a 
lookupS k (Symbol_Table m sts, bs) = 
                case DMap.lookup k m of
                        Nothing -> if null bs 
                                    then Nothing
                                    else lookupS k $ goBack (Symbol_Table m sts, bs)
                        v       -> v

insertS :: String -> a -> Zipper a -> Zipper a
insertS k v (Symbol_Table m sts, bs) = (Symbol_Table (DMap.insert k v m) sts, bs) 

insertT :: Symbol_Table a -> Zipper a -> Zipper a
insertT st (Symbol_Table m sts, bs) = (Symbol_Table m (st DS.<| sts), bs)

focus :: Symbol_Table a -> Zipper a
focus st = (st, [])

defocus :: Zipper a -> Symbol_Table a
defocus (st, bs) = st  

empty_ST :: Symbol_Table a
empty_ST = Symbol_Table (DMap.empty) (DS.empty)  
