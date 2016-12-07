module Mips
( Register(..)
, Operand (..)
, MInstruction (..)
 )
where

data Register = Zero
			| GP | SP | FP | RA
			| V0 | A0 | A1 | A2
			| A3 | V1 | T0 | T1
			| T2 | T3 | T4 | T5
			| T6 | T7 | T8 | T9
			| S0 | S1 | S2 | S3
			| S4 | S5 | S6 | S7
			deriving(Show,Ord,Eq)

data Operand = 	Register Register
			|	Const Int 
			| 	Indexed Int Register
			deriving (Show)

data MInstruction = Comment String
				| PutLabel String String
				| PutDirective String
				| Asciiz String String
				| Add Register Register Register
				| Addi Register Register Register
				| AddS Register Register Register
				| Sub Register Register Register
				| SubS Register Register Register
				| Mul Register Register Register
				| MulS Register Register Register
				| Div Register Register Register
				| DivS Register Register Register
				| Mfhi Register
				| And Register Register Register
				| Or Register Register Register
				| Not Register Register
				| Negi Register Register
				| Negf Register Register
				| Store Register Register 
--				| Lw Register Operand
				deriving(Show)
