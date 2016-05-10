module Symbol_Table
    (Symbol_Table(..)
    ) where

import qualified Data.Map.Strict as DMap
import qualified Data.Sequence   as DS

data Symbol_Table = Symbol_Table Int (DMap.Map String String) (DS.Seq (Symbol_Table)) 
        deriving (Show)
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

goBack :: Zipper -> Zipper
goBack (fcs, []) = (fcs, [])
goBack (st, (Breadcrumbs i p ls rs): bs) = (Symbol_Table i p ((ls DS.|> st) DS.>< rs) , bs)

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
tothetop bc = tothetop $ goBack bc

lookupS :: String -> Zipper -> Maybe String 
lookupS k (Symbol_Table i m sts, bs) = 
                case DMap.lookup k m of
                        Nothing -> if null bs 
                                    then Nothing
                                    else lookupS k $ goBack (Symbol_Table i m sts, bs)
                        v       -> v

insertS :: String -> String -> Zipper -> Zipper 
insertS k v (Symbol_Table i m sts, bs) = (Symbol_Table i (DMap.insert k v m) sts, bs) 


insertT :: Symbol_Table -> Zipper -> Zipper
insertT st (Symbol_Table i m sts, bs) = (Symbol_Table i m (st DS.<| sts), bs)

focus :: Symbol_Table -> Zipper
focus st = (st, [])

defocus :: Zipper -> Symbol_Table 
defocus (st, bs) = st  

empty_ST :: Symbol_Table 
empty_ST = Symbol_Table 0 (DMap.empty) (DS.empty)
