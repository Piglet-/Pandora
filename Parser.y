{

-------------- Parser para el lenguaje de programación Pandora -----------------

module Parser 
    ( parse
    ) where

import Lexer
import Control.Monad.RWS
import SymbolTable
import Type
import qualified Data.Sequence as DS

}
-- reader: string, writer: lista de strings (por ahora)
-- state: tupla (z1,z2) donde z1 = zipper de strings reservados
-- z2 = zipper del resto de las declaraciones

%monad      { RWS String (DS.Seq(Binnacle)) (Zipper,Zipper) }
%name         parse 
%tokentype  { Lexeme Token }
%error      { parseError }

%token
    -- Corchetes -- 
    "["         { Lexeme TokenBracketOpen  _ }
    "]"         { Lexeme TokenBracketClose _ }
    "("         { Lexeme TokenParenOpen _ }
    ")"         { Lexeme TokenParenClose _ }
    
    -- Separadores --
    ","         { Lexeme TokenComma _ }
    ";"         { Lexeme TokenSemicolon _ }
    ":"         { Lexeme TokenColon _ }

    -- acceso a campos --
    "."         { Lexeme TokenPoint _ }

    -- instrucciones --
    "="         { Lexeme TokenAssign _ }
    if          { Lexeme TokenIf     _ }
    then        { Lexeme TokenThen   _ }
    else        { Lexeme TokenElse   _ }
    while       { Lexeme TokenWhile  _ }
    for         { Lexeme TokenFor    _ }
    from        { Lexeme TokenFrom   _ }
    to          { Lexeme TokenTo     _ }
    with        { Lexeme TokenWith   _ }
    do          { Lexeme TokenDo     _ }
    like        { Lexeme TokenLike   _ }
    has         { Lexeme TokenHas    _ }
    return      { Lexeme TokenReturn _ }
    new         { Lexeme TokenNew    _ }
    begin       { Lexeme TokenBegin  _ }
    end         { Lexeme TokenEnd    _ }
    func        { Lexeme TokenFunc   _ }
    proc        { Lexeme TokenProc   _ }
    free        { Lexeme TokenFree   _ }
    repeat      { Lexeme TokenRepeat _ }
    until       { Lexeme TokenUntil  _ }
    read        { Lexeme TokenRead   _ }
    write       { Lexeme TokenWrite  _ }
    of          { Lexeme TokenOf     _ }
    inttostr    { Lexeme TokenITS    _ }
    flotostr    { Lexeme TokenFTS    _ }
    inttoflo    { Lexeme TokenITF    _ }
 
    -- tipos --
    intT        { Lexeme TokenIntT   _ }
    boolT       { Lexeme TokenBoolT  _ }
    floatT      { Lexeme TokenFloatT _ }
    charT       { Lexeme TokenCharT  _ }
    struct      { Lexeme TokenStruct _ }
    union       { Lexeme TokenUnion  _ }
    voidT       { Lexeme TokenVoid   _ }
    array       { Lexeme TokenArray  _ }
    stringT     { Lexeme TokenStringT _ }

    -- constantes booleanas --
    true      { Lexeme TokenTrue  _ }
    false     { Lexeme TokenFalse _ }

    -- null --
    null      { Lexeme TokenNull _ }
   
    -- valor por referencia --
    var         { Lexeme TokenVar _ } 

-------------------------- operadores ---------------------------------
    -- binarios --
    "<"         { Lexeme TokenLT    _ }
    ">"         { Lexeme TokenGT    _ }
    "<="        { Lexeme TokenLE    _ }
    ">="        { Lexeme TokenGE    _ }
    "=="        { Lexeme TokenEq    _ }
    "/="        { Lexeme TokenIneq  _ }
    or          { Lexeme TokenOr    _ }
    and         { Lexeme TokenAnd   _ }
    "+"         { Lexeme TokenPlus  _ }
    "-"         { Lexeme TokenMinus _ }
    "*"         { Lexeme TokenAsterisk _ }
    "/"         { Lexeme TokenDivFloat _ }
    div         { Lexeme TokenDivInt _ }
    mod         { Lexeme TokenMod    _ }
    "^"         { Lexeme TokenCircum _ }

    -- unarios --
    not       { Lexeme TokenNot   _ }
    "->"      { Lexeme TokenArrow _ }

    -- variables --
    int         { Lexeme ( TokenInt    _ ) _ }
    float       { Lexeme ( TokenFloat  _ ) _ }
    char        { Lexeme ( TokenChar   _ ) _ }
    string      { Lexeme ( TokenString _ ) _ }
    id          { Lexeme ( TokenIdent  _ ) _ }

    -- No estoy seguro si va
    "EOF"       { Lexeme TokenEOF _ }

-- Precedencias
%right    "=" 
%nonassoc "<" "<=" ">" ">=" 
%left "==" "/="
%left     or
%left     and
%right    not
%left     "+" "-"
%left     "*" "/" mod div
%left     "^"
%right    NEG

%%

Program : Declarations Main "EOF"  { % return () } -- abrir el primer scope              
	   | Main "EOF"                { % return () } 

Main : begin Insts end  { % return () } -- abrir scope del main

Declaration:  FuncDec OS Insts CS end CS        {% do 
                                                   (z, z') <- get
                                                   tell (snd (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) (fst(snd $1))) (z,DS.empty) (snd (snd $1))))
                                                   put (fst (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) (fst(snd $1))) (z,DS.empty) (snd (snd $1))),z') }
            | struct id has OS StructObjs end CS    { % do 
                                                        (z, z') <- get
                                                        tell (snd (doInsert (makeStruct $1 $5) (z,DS.empty) $2))
                                                        put (fst (doInsert (makeStruct $1 $5) (z,DS.empty) $2), z') }
            | union id like OS StructObjs end CS    { % do 
                                                        (z, z') <- get
                                                        tell (snd (doInsert (makeStruct $1 $5) (z,DS.empty) $2))
                                                        put (fst(doInsert (makeStruct $1 $5) (z,DS.empty) $2), z') }
            | Dec                                       { % return () }
            | Assign                                    { % return () } -- ignorar de momento

StructObjs : StructOb                   { $1 }
            | StructObjs ";" StructOb   { $1 ++ $3 }

StructOb : Type ":" ListId { [(x,y) | x <- $3,  y <- [(makeBtype $1)]] }
            | array of Type Dimen ":" ListId { [(x,y) | x <- $6,  y <- [(makeArray $4 (makeBtype $3))] ] }

FuncDec : TypeFunc OS "(" Param ")"  {% do return (fst $1,($4,snd $1)) }
        
TypeFunc :  Type ":" func id    {% do 
                                   (z, z') <- get
                                   tell( snd (doInsert (makeObj $3 (makeBtype $1) []) (z,DS.empty) $4))
                                   put(fst (doInsert (makeObj $3 (makeBtype $1) []) (z,DS.empty) $4), z')
                                   return (($3,makeBtype $1),$4) } 
        | Type ":" proc id {% do 
                              (z, z') <- get
                              tell( snd (doInsert (makeObj $3 (makeBtype $1) []) (z,DS.empty) $4))
                              put(fst (doInsert (makeObj $3 (makeBtype $1) []) (z,DS.empty) $4), z')
                              return (($3,makeBtype $1),$4)} 

OS: {- Lambda -} { % do 
                     (z, z') <- get 
                     put (openScope z, z')
                 }

CS: {- Lambda -} { % do 
                     (z, z') <- get 
                     put (closeScope z, z')
                 }

Declarations : Declaration { % return () }
    | Declarations Declaration  { % return () }

Decs : Dec          { % return () }
    | Decs Dec      { % return () }

-- y la declaracion de apuntadores?
Dec : Type ":" ListId                      { % do 
                                            (z, z') <- get 
                                            tell (snd (foldl (doInsert (makeBtype $1)) (z,DS.empty)  $3))
                                            put (fst (foldl (doInsert (makeBtype $1)) (z,DS.empty)  $3), z')}
    | array of Type Dimen ":" ListId       { % do
                                            (z , z') <- get
                                            tell (snd (foldl (doInsert (makeArray $4 (makeBtype $3))) (z,DS.empty) $6))
                                            put (fst(foldl (doInsert (makeArray $4 (makeBtype $3))) (z,DS.empty) $6), z') } 
    -- no hace falta foldl
    | Type Astk id  { % do 
                        (z, z') <- get 
                        tell (snd (doInsert (makePointer $2 (makeBtype $1)) (z,DS.empty) $3))
                        put (fst (doInsert (makePointer $2 (makeBtype $1)) (z,DS.empty) $3), z') 
                        }

Astk : "*"     {% return 1}
    | Astk "*" {% return ($1 + 1)}


-- abrir un scope e insertar los parametros
Param: {- lambda -}     { % return [] } 
        | Params        { % return $1 } -- NUEVO

Params: Type ":" id     { % do
                            (z , z') <- get
                            tell (snd (doInsert (makeBtype $1) (z,DS.empty) $3))
                            put ((fst (doInsert (makeBtype $1) (z,DS.empty) $3)), z')
                            return [(makeBtype $1)]} --NUEVO
        | array of Type Dimen ":" id    {% do
                                            (z , z') <- get
                                            tell (snd (doInsert (makeArray $4 (makeBtype $3)) (z,DS.empty) $6))
                                            put ((fst (doInsert (makeArray $4 (makeBtype $3)) (z,DS.empty) $6)), z')
                                            return [(makeBtype $3)]} -- NUEVO
        | var Type ":" id   { % do
                                (z , z') <- get
                                tell (snd (doInsert (makeBtype $2) (z,DS.empty) $4))
                                put ((fst (doInsert (makeBtype $2) (z,DS.empty) $4)), z')
                                return [(makeBtype $2)]} --NUEVO
        | var array of Type Dimen ":" id    { % do
                                                (z , z') <- get
                                                tell (snd (doInsert (makeArray $5 (makeBtype $4)) (z,DS.empty) $7))
                                                put ((fst (doInsert (makeArray $5 (makeBtype $4)) (z,DS.empty) $7)), z')
                                                return [(makeBtype $4)]} --NUEVO
        | Params "," var Type ":" id    {% do
                                            (z , z') <- get
                                            tell (snd (doInsert (makeBtype $4) (z,DS.empty) $6))
                                            put ((fst (doInsert (makeBtype $4) (z,DS.empty) $6)), z') 
                                            return ((makeBtype $4):$1)} --NUEVO
        | Params "," var array of Type Dimen ":" id     {% do
                                                            (z , z') <- get
                                                            tell (snd (doInsert (makeArray $7 (makeBtype $6)) (z,DS.empty) $9))
                                                            put ((fst (doInsert (makeArray $7 (makeBtype $6)) (z,DS.empty) $9)), z') 
                                                            return ((makeBtype $6):$1)} --NUEVO
        | Params "," Type ":" id    { % do
                                        (z , z') <- get
                                        tell (snd (doInsert (makeBtype $3) (z,DS.empty) $5))
                                        put ((fst (doInsert (makeBtype $3) (z,DS.empty) $5)), z')
                                        return ((makeBtype $3):$1)} --NUEVO
        | Params "," array of Type Dimen ":" id     { % do
                                                        (z , z') <- get
                                                        tell (snd (doInsert (makeArray $6 (makeBtype $5)) (z,DS.empty) $8))
                                                        put ((fst (doInsert (makeArray $6 (makeBtype $5)) (z,DS.empty) $8)), z')
                                                        return ((makeBtype $5):$1) } --NUEVO

Type : intT     { $1 } 
    | floatT    { $1 }
    | stringT   { $1 }
    | charT     { $1 }
    | boolT     { $1 }
    | voidT     { $1 }
    | id        { $1 }

Dimen : "[" Exp "]"             { % return 1 }
        | Dimen "[" Exp "]"     { % return ($1 + 1) } -- CAMBIAR INSERT DE ARREGLOS

Exps : Exp          { % return () }
    | Exps "," Exp  { % return () }

Values : true               { $1 }
    | false                 { $1 }
    | null                  { $1 }
    | int                   { $1 }
    | float                 { $1 }
    | char                  { $1 }

Exp : Values                { % return () }
    | id                    { % do
                                    (z, z') <- get
                                    put (fst (findId $1 z),z') 
                                    tell (snd (findId $1 z)) }
    | Exp "+" Exp           { % return () }
    | Exp "-" Exp           { % return () }
    | Exp "/" Exp           { % return () }
    | Exp "^" Exp           { % return () }
    | Exp "*" Exp           { % return () }
    | Exp div Exp           { % return () }
    | Exp mod Exp           { % return () }
    | Exp ">" Exp           { % return () }
    | Exp ">=" Exp          { % return () }
    | Exp "<" Exp           { % return () }
    | Exp "<=" Exp          { % return () }
    | Exp "==" Exp          { % return () }
    | Exp "/=" Exp          { % return () }
    | Exp and Exp           { % return () }
    | Exp or Exp            { % return () }
    | "-" Exp   %prec NEG   { % return () }
    | not Exp   %prec NEG   { % return () }
    | "->" Exp  %prec NEG   { % return () }
    | Accesor               { % return () }
    | CFunctions            { % return () }
    | "(" Exp ")"           { % return () }
    | "[" Exps "]"          { % return () }
    | string                { % do 
                                (z, z') <- get
                                put (z, doInsertStr StringT z' $1)
                                }

Assign : id "=" Exp  ";"        { % do 
                                    (z, z') <- get
                                    put (fst (findIdA $1 z),z') 
                                    tell (snd (findIdA $1 z)) }
        | id "=" InstA          {% do 
                                    (z, z') <- get
                                    put (fst (findIdA $1 z),z') 
                                    tell (snd (findIdA $1 z)) }
        | Accesor "=" Exp ";"   { % return () }

ListId : id                 { [$1] }
        | ListId "," id     {  $3 : $1 }

Accesor : id Accs { % do 
                        (z, z') <- get
                        put (fst (findId $1 z),z') 
                        tell (snd (findId $1 z))}

Accs: Acc       { % return () }
    | Accs Acc  { % return () }

Acc : "." id        { % return () }
    | "[" Exp "]"   { % return () }

FuncCall : id "(" Fields ")" { % do 
                                    (z, z') <- get
                                    put (fst (findId $1 z),z') 
                                    tell (snd (findId $1 z))}

Fields : {- lambda -}       { % return () }
        | Exp               { % return () }
        | Fields "," Exp    { % return () }

CFunctions : inttostr "(" Exp ")"   { % return () }
            | flotostr "(" Exp ")"  { % return () }
            | inttoflo "(" Exp ")"  { % return () }

Insts : Inst            { % return () }
        | Insts Inst    { % return () }

-- poner Dec, Write, Return, free en Inst
-- y poner el ";" en Inst
InstA : read Exp ";"      { % return () }
    | FuncCall ";"      { % return () }

Inst : InstA            { % return () }
    | Assign            { % return () } 
    | Dec ";"           { % return () }
    | Write             { % return () }
    | Return            { % return () }
    | free Exp ";"      { % return () }
    | InstB             { % return () }

InstB: If               { % return () }
    | While             { % return () }
    | Repeat            { % return () }
    | For               { % return () }

Return : return Exp ";"  	{ % return () }
	|return FuncCall ";" 	{ % return () } 

Write : write Exp ";"       { % return () }
	| write FuncCall ";"    { % return () }

If : if "(" Exp ")" then Block                      { % return () }
    | if "(" Exp ")" then Block else Insts end      { % return () }

For : for OS "(" Range ")" do Block CS  { % return () }

Range : It from Exp to Exp with Exp  { % return () }
It : id { % do 
                (z, z') <- get
                put (fst $ doInsert IteratorT (z,DS.empty) $1, z')
                tell (snd (doInsert IteratorT (z,DS.empty) $1)) }

While : while "(" Exp ")" do Block  { % return () }

Repeat : repeat OS Insts until Exp CS  { % return () }

Block : OS Insts end CS { % return () } -- abrir y cerrar el scope

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)


-- en lugar de lexeme token, DS.seq (Lexeme Token) y hacer
-- fold que inserte en el zipper.
doInsert:: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsert VoidT (z,_) l@(Lexeme (TokenIdent s) p) = 
     (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                    " can't be declared as void")))

doInsert (TypeT t) (z,_) l@(Lexeme (TokenIdent s) p) =
    case lookupS t z of
        Nothing -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " in " ++ show p ++
                                      " not declared")))
        Just ((Entry st pos),_) -> 
            case st of
                StructT _ ->  
                    case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))
                UnionT _ -> case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))
                _ -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " in " ++ show p ++
                                      " not declared")))


doInsert t (z,_) l@(Lexeme (TokenIdent s) p) = 
    case lookupS' s z of
        Nothing -> (insertS s (Entry t p) z, DS.singleton(Right $ ""))
        Just (Entry typ pos) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))

doInsertFun :: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsertFun t (z,_) l@(Lexeme (TokenIdent s) p) = 
    (insertS s (Entry t p) z, DS.singleton(Right $ ""))


doInsertStr:: Type -> Zipper -> Lexeme Token -> Zipper
doInsertStr t z l@(Lexeme (TokenString s) p) = 
    case lookupS' s z of
        Nothing -> insertS s (Entry t p) z
        _ -> z
 
findId :: Lexeme Token -> Zipper -> (Zipper, DS.Seq(Binnacle))
findId l@(Lexeme (TokenIdent s) p) z =  case lookupS s z of
                Nothing -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " is not defined")))
                Just v  -> (z, DS.singleton (Right $ ""))

findIdA :: Lexeme Token -> Zipper -> (Zipper, DS.Seq(Binnacle))
findIdA l@(Lexeme (TokenIdent s) p) z =  case lookupS s z of
                Nothing -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " is not defined")))
                Just ((Entry t p),scp)  -> if t == IteratorT 
                                            then (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " can't be assigned")))
                                            else (z, DS.singleton (Right $ ""))

}
