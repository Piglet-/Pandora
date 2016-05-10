module Symbol_Table
    (Symbol_Table(..)
    ) where

import qualified Data.Map.Strict as DMap


data Symbol_Table a = Symbol_Table (DMap.Map String a) [Symbol_Table a] deriving (Show)
data Breadcrumbs  a = Breadcrumbs (DMap.Map String a)  [Symbol_Table a] [Symbol_Table a] deriving (Show) 
type Zipper a = (Symbol_Table a, [Breadcrumbs a]) 

goDown :: Zipper a -> Maybe (Zipper a)
goDown (Symbol_Table _ [], _) = Nothing
goDown (Symbol_Table f (st: sts), bs) = Just (st, Breadcrumbs f [] sts: bs) 

goBack :: Zipper a -> Zipper a
goBack (fcs, []) = (fcs, [])
goBack (st, (Breadcrumbs p ls rs): bs) = (Symbol_Table p (ls ++ [st] ++ rs) , bs)

tothetop :: Zipper a -> Zipper a
tothetop (fcs, []) = (fcs, []) 
tothetop bc = tothetop $ goBack bc

lookupS :: String -> Zipper a -> Maybe a 
lookupS k (Symbol_Table m sts, bs) = 
                case DMap.lookup k m of
                        Nothing -> if null bs 
                        			then Nothing
                        			else lookupS k $ goBack (Symbol_Table m sts, bs)
                        v  		-> v

insertS :: String -> a -> Zipper a -> Zipper a
insertS k v (Symbol_Table m sts, bs) = (Symbol_Table (DMap.insert k v m) sts, bs) 

insertT :: Symbol_Table a -> Zipper a -> Zipper a
insertT st (Symbol_Table m sts, bs) = (Symbol_Table m (st:sts), bs)

focus :: Symbol_Table a -> Zipper a
focus st = (st, [])

defocus :: Zipper a -> Symbol_Table a
defocus (st, bs) = st 