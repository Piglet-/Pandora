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
			deriving(Ord,Eq)

instance Show Register where
	show r = case r of
		Zero -> "$zero"
		GP 	-> "$gp"
		FP -> "$fp"
		SP -> "$sp"
		RA -> "$ra"
		V0 -> "$v0" 
		A0 -> "$a0"
		A1 -> "$a1"
		A2 -> "$a2"
		A3 -> "$a3" 
		V1 -> "$v1" 
		T0 -> "$t0" 
		T1 -> "$t1"
		T2 -> "$t2" 
		T3 -> "$t3" 
		T4 -> "$t4" 
		T5 -> "$t5"
		T6 -> "$t6"
		T7 -> "$t7"
		T8 -> "$t8" 
		T9 -> "$t9"
		S0 -> "$s0" 
		S1 -> "$s1" 
		S2 -> "$s2" 
		S3 -> "$s3"
		S4 -> "$s4"
		S5 -> "$s5"
		S6 -> "$s6"
		S7 -> "$s7"

data Operand = 	Register Register
			|	Const Int 
			| 	Indexed Int Register

instance Show Operand where
	show op = case op of
		Register r -> show r
		Const i -> show i
		Indexed i r -> show i ++ "(" ++ show r ++ ")"

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
				| Sw Register Operand 
				| Lw Register Operand
				| B String
				| Beq Register Register String
				| Bne Register Register String
				| Bgt Register Register String
				| Blt Register Register String
				| Bge Register Register String
				| Ble Register Register String

instance Show MInstruction where
	show ins = case ins of
		Comment s -> "# " ++ s
		PutLabel s1 s2 -> 	s1 ++ ":" ++ "   #" ++ s2
		PutDirective s -> 	s
		Asciiz s1 s2 -> 	s1 ++ ": .asciiz " ++ s2
		Add r1 r2 r3 -> 	"add   "  ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Addi r1 r2 r3 -> 	"addi  "  ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		AddS r1 r2 r3 -> 	"add.s " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Sub r1 r2 r3 ->  	"sub   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		SubS r1 r2 r3 -> 	"sub.s " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Mul r1 r2 r3 -> 	"mul   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		MulS r1 r2 r3 -> 	"mul.s " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Div r1 r2 r3 -> 	"div   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		DivS r1 r2 r3 -> 	"div.s " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Mfhi r -> 			"mfhi  " ++ show r
		And r1 r2 r3 -> 	"and   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Or r1 r2 r3 -> 		"or    " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show r3
		Not r1 r2 ->		"neg   " ++ show r1 ++ ", " ++ show r2
		Negi r1 r2 ->		"neg   " ++ show r1 ++ ", " ++ show r2
		Negf r1 r2 ->		"neg.s " ++ show r1 ++ ", " ++ show r2
		Sw r op ->			"sw    " ++ show r ++ ", " ++ show op
		Lw r op ->			"lw    " ++ show r ++ ", " ++ show op
		B s ->				"b     " ++ s
		Beq r1 r2 s ->		"beq   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s
		Bne r1 r2 s ->		"bne   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s
		Bgt r1 r2 s ->		"bgt   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s
		Blt r1 r2 s ->		"blt   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s
		Bge r1 r2 s ->		"bge   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s
		Ble r1 r2 s ->		"ble   " ++ show r1 ++ ", " ++ show r2 ++ ", " ++ show s