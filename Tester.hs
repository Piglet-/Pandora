module Tester() where
import Symbol_Table
import System.IO
import Data.Char (toLower)
import Data.Maybe (fromJust)

beginTester :: IO ()
beginTester = do
	tester firstScope 


tester :: Zipper -> IO ()
tester z = do
	putStr "What?\n"
	line <- getLine
	case (map toLower line) of
		"open" 		-> openScope z
		"close" 	-> closeScope z
		"insert" 	-> insertVar z
		"quit"		-> quitTester z
		"print"		-> printScopes z
	
firstScope :: Zipper
firstScope = focus $ empty_ST 0

openScope :: Zipper -> IO ()
openScope z = do
	putStr "Opened scope.\n"
	tester (fromJust $ goDown $ insertT z)

closeScope :: Zipper -> IO ()
closeScope z = do
	case goBack z of
		Nothing -> do 
			putStr "Bye..\n"
			printScopes z
		Just z' -> do
			putStr "Done. \n"
			tester z'  

insertVar :: Zipper -> IO ()
insertVar z = do
	putStr "Name? \n"
	line <- getLine
	case (lookupS line z) of
		Nothing -> do
			putStr "Inserted.\n" 
			tester (insertS line line z)
		v 		-> do
			putStr "Variable already declared in this scope.\n"
			tester z 

printScopes :: Zipper -> IO ()
printScopes (st, bs) = do
	print st
	tester (st,bs)

quitTester :: Zipper -> IO ()
quitTester z = do
		putStr "Bye.. \n"
		print (tothetop z)
