module Instructions (
	Instructions(..)
	,AST(..)
	,module Expression
)
where

import Position
import Expression

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
	| NewL 		Expression
	| FreeL 	Expression		Position
	| None
	deriving(Show, Eq)

data AST = AST [Instructions] deriving (Eq, Show)