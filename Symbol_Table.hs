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

--lookup :: Zipper a -> String -> Maybe a 
--lookup (Symbol_Table m _, []) k = DMap.lookup k m
--lookup (Symbol_Table m _, bs) k = 
--                case DMap.lookup k m of
--                        Nothing -> DMap.lookup $ goBack (Symbol_Table m _, bs)
--                        Just v  -> Just v
