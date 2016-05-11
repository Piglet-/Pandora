module Tester(
beginTester) where
import Symbol_Table
import System.IO
import Data.Char (toLower)
import Data.Maybe (fromJust)

beginTester :: IO ()
beginTester = do
	putStr "\nInstructions: \n\n"
	putStr "Write \'open\' to open a new scope inside the current scope.\n"
	putStr "Write \'close\' to close the current scope.\n"
	putStr "Write \'insert\' to add a new variable into the current scope.\n"
	putStr "Write \'print\' to show the content of the current scope.\n"
	putStr "Write \'find\' to find a variable.\n"
	putStr "Write \'quit\' to exit and print all the symbol table.\n\n"
	tester firstScope 


tester :: Zipper -> IO ()
tester z = do
	putStr "What?\n"
	line <- getLine
	case (toLower $ head line) of
		'o' 	-> openScope z
		'c' 	-> closeScope z
		'i'	 	-> insertVar z
		'q'		-> quitTester z
		'p'		-> printScopes z
		'f'		-> findSimbol z
	
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
	putStr "What name? \n"
	line <- getLine
	case (lookupS' line z) of
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
		print st 
			where (st,bs) = (tothetop z)

findSimbol :: Zipper -> IO ()
findSimbol z = do
		putStr "What name?\n"
		line <- getLine
		case (lookupS line z) of
			Nothing -> do
				putStr "Variable not found.\n"
				tester z
			Just (x,y) -> do
				putStr $ "Variable " ++ show x ++ " found in level " ++ show y ++ "\n"
				tester z
