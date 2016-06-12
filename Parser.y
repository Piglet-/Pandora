{

-------------- Parser para el lenguaje de programación Pandora -----------------

module Parser 
    ( parse
    ) where

import Lexer
import Control.Monad.RWS
import SymbolTable
import Type
import Data.Maybe
import qualified Data.Map.Strict as DMap
import qualified Data.Sequence as DS

}
-- reader: string, writer: lista de strings (por ahora)
-- state: tupla (z1,z2) donde z1 = zipper de strings reservados
-- z2 = zipper del resto de las declaraciones

%monad      { RWS String (DS.Seq(Binnacle)) State }
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

Program : Declarations Main "EOF"  { % return (instruc ($2:[$1])) }             
	   | Main "EOF"                { % return  $1 } 

Main : begin Insts end  { % return $2 } 

Declaration:  FuncDec OS Insts CS end CS        {% return $3 }
            | struct id has OS StructObjs ";" end CS    { % do 
                                                        st <- get
                                                        tell (snd (doInsert (makeStruct $1 $5) ((syt st),DS.empty) $2))
                                                        put $ State (fst (doInsert (makeStruct $1 $5) ((syt st),DS.empty) $2)) (srt st) (off st)  
                                                        return VoidT}
            | union id like OS StructObjs ";" end CS    { % do 
                                                        st <- get
                                                        tell (snd (doInsert (makeStruct $1 $5) ((syt st),DS.empty) $2))
                                                        put $ State (fst(doInsert (makeStruct $1 $5) ((syt st),DS.empty) $2)) (srt st) (off st)
                                                        return VoidT  }
            | Dec                                       { % return $1 }
            | Assign                                    { % return $1 } 

StructObjs : StructOb                   { $1 }
            | StructObjs ";" StructOb   { $1 ++ $3 }

StructOb : Type ":" ListId { [(x,y) | x <- $3,  y <- [(makeBtype $1)]] }
            | array of Type Dimen ":" ListId { [(x,y) | x <- $6,  y <- [(makeArray $4 (makeBtype $3))] ] }
            | Type Astk id {[($3, (makePointer $2 (makeBtype $1)))]}

FuncDec : TypeFunc OS "(" Param ")"  {% do 
                                        st <- get
                                        tell (snd (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) $4) ((syt st),DS.empty) (snd $1)))
                                        put $ State (fst (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) $4) ((syt st),DS.empty) (snd $1))) (srt st) (off st)
                                        return (fst $1,($4,snd $1)) }
        
TypeFunc :  Type ":" func id    {% do 
                                   st <- get
                                   tell( snd (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4))
                                   put $ State (fst (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4)) (srt st) (off st)
                                   return (($3,makeBtype $1),$4) } 
        | Type ":" proc id {% do 
                              st <- get
                              tell( snd (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4))
                              put $ State (fst (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4)) (srt st) (off st)
                              return (($3,makeBtype $1),$4)} 

OS: {- Lambda -} { % do 
                     st <- get 
                     put $ State (openScope (syt st)) (srt st) 0
                 }

CS: {- Lambda -} { % do 
                     st <- get 
                     put $ State (closeScope (syt st)) (srt st) (off st)
                 }

Declarations : Declaration { % return (instrucS $1) }
    | Declarations Declaration  { % return (instruc ($2:[$1])) }

Dec : Type ":" ListId                      { % do 
                                            st <- get 
                                            tell (snd (foldl (doInsert (makeBtype $1)) ((syt st),DS.empty)  $3))
                                            put $ State (fst (foldl (doInsert (makeBtype $1)) ((syt st),DS.empty)  $3)) (srt st) (off st)
                                            return VoidT}
    | array of Type Dimen ":" ListId       { % do
                                            st <- get
                                            tell (snd (foldl (doInsert (makeArray $4 (makeBtype $3))) ((syt st),DS.empty) $6))
                                            put $ State (fst(foldl (doInsert (makeArray $4 (makeBtype $3))) ((syt st),DS.empty) $6)) (srt st) (off st)
                                            return VoidT } 
    | Type Astk id  { % do 
                        st <- get 
                        tell (snd (doInsert (makePointer $2 (makeBtype $1)) ((syt st),DS.empty) $3))
                        put $ State (fst (doInsert (makePointer $2 (makeBtype $1)) ((syt st),DS.empty) $3)) (srt st) (off st)
                        return VoidT 
                        }

Astk : "*"     {% return 1}
    | Astk "*" {% return ($1 + 1)}


Param: {- lambda -}     { % return [] } 
        | Params        { % return $1 } 

Params: Type ":" id     { % do
                            st <- get
                            tell (snd (doInsert (makeBtype $1) ((syt st),DS.empty) $3))
                            put $ State (fst (doInsert (makeBtype $1) ((syt st),DS.empty) $3)) (srt st) (off st)
                            return [(makeBtype $1)]} 
        | array of Type Dimen ":" id    {% do
                                            st <- get
                                            tell (snd (doInsert (makeArray $4 (makeBtype $3)) ((syt st),DS.empty) $6))
                                            put $ State (fst (doInsert (makeArray $4 (makeBtype $3)) ((syt st),DS.empty) $6)) (srt st) (off st)
                                            return [(makeBtype $3)]} 
        | var Type ":" id   { % do
                                st <- get
                                tell (snd (doInsert (makeBtype $2) ((syt st),DS.empty) $4))
                                put $ State (fst (doInsert (makeBtype $2) ((syt st),DS.empty) $4)) (srt st) (off st)
                                return [(makeBtype $2)]} 
        | var array of Type Dimen ":" id    { % do
                                                st <- get
                                                tell (snd (doInsert (makeArray $5 (makeBtype $4)) ((syt st),DS.empty) $7))
                                                put $ State (fst (doInsert (makeArray $5 (makeBtype $4)) ((syt st),DS.empty) $7)) (srt st) (off st)
                                                return [(makeBtype $4)]} 
        | Params "," var Type ":" id    {% do
                                            st <- get
                                            tell (snd (doInsert (makeBtype $4) ((syt st),DS.empty) $6))
                                            put $ State (fst (doInsert (makeBtype $4) ((syt st),DS.empty) $6)) (srt st) (off st) 
                                            return ((makeBtype $4):$1)} 
        | Params "," var array of Type Dimen ":" id     {% do
                                                            st <- get
                                                            tell (snd (doInsert (makeArray $7 (makeBtype $6)) ((syt st),DS.empty) $9))
                                                            put $ State (fst (doInsert (makeArray $7 (makeBtype $6)) ((syt st),DS.empty) $9)) (srt st) (off st) 
                                                            return ((makeBtype $6):$1)} 
        | Params "," Type ":" id    { % do
                                        st <- get
                                        tell (snd (doInsert (makeBtype $3) ((syt st),DS.empty) $5))
                                        put $ State (fst (doInsert (makeBtype $3) ((syt st),DS.empty) $5)) (srt st) (off st)
                                        return ((makeBtype $3):$1)} 
        | Params "," array of Type Dimen ":" id     { % do
                                                        st <- get
                                                        tell (snd (doInsert (makeArray $6 (makeBtype $5)) ((syt st),DS.empty) $8))
                                                        put $ State (fst (doInsert (makeArray $6 (makeBtype $5)) ((syt st),DS.empty) $8)) (srt st) (off st)
                                                        return ((makeBtype $5):$1) }

Type : intT     { $1 } 
    | floatT    { $1 }
    | stringT   { $1 }
    | charT     { $1 }
    | boolT     { $1 }
    | voidT     { $1 }
    | id        { $1 }

Dimen : "[" int "]"             { % return 1 }
        | Dimen "[" int "]"     { % return ($1 + 1) } 

Values : true               { BoolT }
    | false                 { BoolT }
    | null                  { VoidT }
    | int                   { IntT }
    | float                 { FloatT }
    | char                  { CharT }

Exp : Values                { % return $1 }
    | id                    { % do
                                    st <- get
                                    tell (snd (findId $1 (syt st))) 
                                    return (typeToken $1 (syt st)) }
    | Exp "+" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp $1 $2 $3 "+"))
                                    return (fst (binNumExp $1 $2 $3 "+")) }
    | Exp "-" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp $1 $2 $3 "-"))
                                    return (fst (binNumExp $1 $2 $3 "-")) }
    | Exp "/" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp $1 $2 $3 "/"))
                                    return (fst (binNumExp $1 $2 $3 "/")) }
    | Exp "^" Exp           { % do  
                                    st <- get -- No estoy seguro cuales serian los tipos
                                    tell (snd (binNumExp $1 $2 $3 "^")) 
                                    return (fst (binNumExp $1 $2 $3 "^")) }
    | Exp "*" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp $1 $2 $3 "*"))
                                    return (fst (binNumExp $1 $2 $3 "*")) }
    | Exp div Exp           { % do 
                                    st <- get --Creo que oslo serian Enteros
                                    tell (snd (binNumExp $1 $2 $3 "div"))
                                    return (fst (binNumExp $1 $2 $3 "div")) }
    | Exp mod Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp $1 $2 $3 "mod"))
                                    return (fst (binNumExp $1 $2 $3 "mod")) }
    | Exp ">" Exp           { % do 
                                    st <- get 
                                    tell (snd (relExp $1 $2 $3 ">"))
                                    return (fst (relExp $1 $2 $3 ">")) }
    | Exp ">=" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp $1 $2 $3 ">="))
                                    return (fst (relExp $1 $2 $3 ">=")) }
    | Exp "<" Exp           { % do 
                                    st <- get 
                                    tell (snd (relExp $1 $2 $3 "<"))
                                    return (fst (relExp $1 $2 $3 "<")) }
    | Exp "<=" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp $1 $2 $3 "<="))
                                    return (fst (relExp $1 $2 $3 "<=")) }
    | Exp "==" Exp          { % do 
                                    st <- get 
                                    tell (snd (eqExp $1 $2 $3 "=="))
                                    return (fst (eqExp $1 $2 $3 "==")) }
    | Exp "/=" Exp          { % do 
                                    st <- get 
                                    tell (snd (eqExp $1 $2 $3 "/="))
                                    return (fst (eqExp $1 $2 $3 "/=")) }
    | Exp and Exp           { % do 
                                    st <- get 
                                    tell (snd (binBoolExp $1 $2 $3 "and"))
                                    return (fst (binBoolExp $1 $2 $3 "and")) }
    | Exp or Exp            { % do 
                                    st <- get 
                                    tell (snd (binBoolExp $1 $2 $3 "or"))
                                    return (fst (binBoolExp $1 $2 $3 "or")) }
    | "-" Exp   %prec NEG   { % do 
                                    tell (snd (numExp $1 $2 "-"))
                                    return (fst (numExp $1 $2 "-")) }
    | not Exp   %prec NEG   { % do 
                                    tell (snd (numExp $1 $2 "not"))
                                    return (fst (numExp $1 $2 "not")) }
    | "->" Exp  %prec NEG   { % do 
                                    tell (snd (pointExp $1 $2 "->"))
                                    return (fst (pointExp $1 $2 "->")) }
    | Accesor               { % return $1 }
    | CFunctions            { % return $1 }
    | "(" Exp ")"           { % return $2 }
    | string                { % do 
                                st <- get
                                put $ State (syt st) (doInsertStr StringT (srt st) $1) (off st)
                                return StringT
                                }

Assign : id "=" Exp  ";"        { % do 
                                    st <- get 
                                    tell (snd (findIdA $1 $3 (syt st)))
                                    return (fst (findIdA $1 $3 (syt st))) }
        | id "=" InstA          {% do 
                                    st <- get 
                                    tell (snd (findIdA $1 $3 (syt st)))
                                    return (fst (findIdA $1 $3 (syt st)))}

        | Accesor "=" Exp ";"   { % do
                                    tell (snd (matchAcc $1 $3 $2))
                                    return (fst(matchAcc $1 $3 $2)) }

ListId : id                 { [$1] }
        | ListId "," id     {  $3 : $1 }

Accesor : id Arrays { % do 
                        st <- get 
                        tell (snd (findId $1 (syt st)))
                        return(fst(isArray(typeToken $1 (syt st)) $2))}
        | id Accs  { % do 
                        st <- get 
                        tell (snd (isTypeT (typeToken $1 (syt st)) (reverse $2) (syt st)))
                        return (fst(isTypeT (typeToken $1 (syt st)) (reverse $2) (syt st)))}

Accs: Acc       { % return [$1] }
    | Accs Acc  { % return ($2:$1) }

Acc : "." id        { % return $2 }

Arrays : Array        { % return [$1] }
       | Arrays Array { % return ($2:$1) }

Array : "[" int "]"   { % return IntT }

FuncCall : id "(" Fields ")" { % do 
                                    st <- get 
                                    tell (snd (findFunc $1 $3 (syt st)))
                                    return (fst (findFunc $1 $3 (syt st))) }

Fields : {- lambda -}       { % return [] }
        | Exp               { % return ([$1]) }
        | FuncCall          { % return ([$1])}
        | Fields "," Exp    { % return ($3:$1) }
        | Fields "," FuncCall { % return ($3:$1)}

CFunctions : inttostr "(" Exp ")"   { % return (ifInt $3 StringT ) } 
            | flotostr "(" Exp ")"  { % return (ifFloat $3 StringT) } 
            | inttoflo "(" Exp ")"  { % return (ifInt $3 FloatT) } 

Insts : Inst            { % return (instrucS $1) }
        | Insts Inst    { % return (instruc ($2:[$1])) }


InstA : read Exp ";"    { % return $2 } 
    | FuncCall ";"      { % return $1 } 

Inst : InstA            { % return $1  }
    | Assign            { % return $1 } 
    | Dec ";"           { % return $1 }
    | Write             { % return $1 }
    | Return            { % return $1 }
    | free Exp ";"      { % do  
                            tell (snd (freeInst $2 $1))
                            return (fst (freeInst $2 $1)) } 
    | InstB             { % return $1 }

InstB: If               { % return $1 }
    | While             { % return $1 }
    | Repeat            { % return $1 }
    | For               { % return $1 }

Return : return Exp ";"  	{ % return $2 } 
	|return FuncCall ";" 	{ % return $2 } 

Write : write Exp ";"       { % do 
                                tell (snd (writeInst $2))
                                return (fst (writeInst $2)) } -- verificar string
	| write FuncCall ";"    { % do 
                                tell (snd (writeInst $2))
                                return (fst (writeInst $2)) } -- tampoco se

If : if "(" Exp ")" then Block  { % do 
                                    tell (snd (ifInst $3 $1 $6))
                                    return (fst (ifInst $3 $1 $6)) } 
    | if "(" Exp ")" then Block else Insts end  {% do 
                                                    tell (snd (ifElseInst $3 $1 $6 $8))
                                                    return (fst (ifElseInst $3 $1 $6 $8)) }

For : for OS "(" Range ")" do Block CS  { % do 
                                        st <- get 
                                        tell (snd (forInst $4 $7 $1))
                                        return (fst (forInst $4 $7 $1)) } 

Range : It from Exp to Exp with Exp  { % do 
                                        st <- get 
                                        tell (snd (rangeVef $3 $5 $7))
                                        return (fst (rangeVef $3 $5 $7)) }
It : id { % do 
                st <- get
                put $ State (fst $ doInsert IteratorT ((syt st),DS.empty) $1) (srt st) (off st)
                tell (snd (doInsert IteratorT ((syt st),DS.empty) $1)) }

While : while "(" Exp ")" do Block  { % do
                                        st <- get
                                        tell (snd (whileInst $3 $1 $6))
                                        return (fst (whileInst $3 $1 $6)) }

Repeat : repeat OS Insts until Exp CS  { % do
                                        st <- get
                                        tell (snd (whileInst $5 $1 $3))
                                        return (fst (whileInst $5 $1 $3)) }

Block : OS Insts end CS { % return $2 } 

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)


doInsert:: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsert VoidT (z,_) l@(Lexeme (TokenIdent s) p) = 
     (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                    " can't be declared as void")))

doInsert (TypeT t) (z,_) l@(Lexeme (TokenIdent s) p) =
    case lookupS t z of
        Nothing -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " in " ++ show p ++
                                      " not declared")))
        Just ((Entry st pos sz o),_) -> 
            case st of
                StructT _ ->  
                    case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p sz 0) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))
                UnionT _ -> case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p sz 0) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))
                _ -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " in " ++ show p ++
                                      " not declared")))


doInsert t (z,_) l@(Lexeme (TokenIdent s) p) = 
    case lookupS' s z of
        Nothing -> (insertS s (Entry t p (typeSize t) 0) z, DS.singleton(Right $ ""))
        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++
                                      " already declared in " ++ show pos)))

doInsertFun :: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsertFun t (z,_) l@(Lexeme (TokenIdent s) p) = 
    (fromJust (goDown (insertS s (Entry t p (typeSize t) 0) (fromJust(goBack z)))), DS.singleton(Right $ ""))


doInsertStr:: Type -> Zipper -> Lexeme Token -> Zipper
doInsertStr t z l@(Lexeme (TokenString s) p) = 
    case lookupS' s z of
        Nothing -> insertS s (Entry t p 0 0) z
        _ -> z
 
findId :: Lexeme Token -> Zipper -> (Zipper, DS.Seq(Binnacle))
findId l@(Lexeme (TokenIdent s) p) z =  case lookupS s z of
                Nothing -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " is not defined")))
                Just v  -> (z, DS.singleton (Right $ ""))

findIdA :: Lexeme Token -> Type -> Zipper -> (Type, DS.Seq(Binnacle))
findIdA l@(Lexeme (TokenIdent s) p) ty z =  case lookupS s z of
                Nothing -> (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " is not defined")))
                Just ((Entry t p sz o),scp)  -> if t == IteratorT 
                                            then (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " in " ++ show p ++ " can't be assigned")))
                                            else if t == ty 
                                                then (VoidT, DS.singleton (Right $ ""))
                                                else (TypeError, DS.singleton (Left $ ("TypeError " ++ show s ++ " " ++ show p ++ " given " ++ show ty 
                                                    ++ " expecting " ++ show t )))

findFunc :: Lexeme Token -> [Type] -> Zipper -> (Type, DS.Seq(Binnacle))
findFunc l@(Lexeme (TokenIdent s) p) ts z =  case lookupS s z of
                Nothing                 -> (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " in " 
                                            ++ show p ++ " is not defined")))
                Just ((Entry t@(FuncT ty lts) pos sz o),scp)  -> 
                                            case matchType t ts of
                                                TypeError -> (TypeError, DS.singleton (Left $ ("TypeError " ++ show s ++ " " 
                                                            ++ show p ++ " expecting " ++ show (reverse lts) ++ 
                                                            " but have " ++ show (reverse ts))))
                                                v         -> (v,DS.singleton (Right $ ""))

typeToken :: Lexeme Token -> Zipper -> Type
typeToken (Lexeme (TokenIdent s) _) z = case lookupS s z of
                Nothing                -> TypeError
                Just ((Entry t p sz o),scp) -> t 

binExp :: Type -> Type -> (Type, DS.Seq(Binnacle))
binExp IntT   IntT      = (IntT , DS.singleton (Right $ ""))
binExp FloatT FloatT    = (FloatT , DS.singleton (Right $ ""))
binExp IteratorT IntT   = (IntT , DS.singleton (Right $ ""))
binExp IntT IteratorT   = (IntT , DS.singleton (Right $ ""))
binExp TypeError _      = (TypeError , DS.singleton (Right $ "")) --nuevo
binExp _ TypeError      = (TypeError , DS.singleton (Right $ "")) -- nuevo
binExp _ _              = (TypeError , DS.singleton (Left $ "TypeError"))


binNumExp :: Type -> Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
binNumExp IntT   _ IntT _       = (IntT , DS.singleton (Right $ ""))
binNumExp FloatT _ FloatT _     = (FloatT , DS.singleton (Right $ ""))
binNumExp IteratorT _ IntT _    = (IntT , DS.singleton (Right $ ""))
binNumExp IntT _ IteratorT _    = (IntT , DS.singleton (Right $ ""))
binNumExp TypeError _ _ _       = (TypeError,DS.singleton (Right $ "")) -- nuevo
binNumExp _ _ TypeError _       = (TypeError,DS.singleton (Right $ "")) -- nuevo
binNumExp t1 (Lexeme t p) t2 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ show t2 
                    ++ "expecting Int Int or Float Float" ))

relExp :: Type -> Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
relExp IntT _ IntT _ = (BoolT, DS.singleton (Right $ ""))
relExp FloatT _ FloatT _ = (BoolT, DS.singleton (Right $ ""))
relExp CharT _ CharT _ = (BoolT, DS.singleton (Right $ ""))
relExp TypeError _ _ _ = (TypeError , DS.singleton (Right $ "")) -- nuevo
relExp _ _ TypeError _ = (TypeError , DS.singleton (Right $ "")) --nuevo
relExp t1 (Lexeme t p) t2 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ show t2 
                    ++ "expecting Int Int, Float Float or Char Char" ))

eqExp :: Type -> Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
eqExp (TypeT s1) (Lexeme t p) (TypeT s2) s = 
    if s1 == s2 
        then (BoolT, DS.singleton (Right $ ""))
        else (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show s1 ++ show s2 
                    ++ "expecting T1 T2 of the same type" ))
eqExp t1 (Lexeme t p) t2 s = 
    if t1 == TypeError || t2 == TypeError --nuevo
        then (TypeError , DS.singleton (Right $ "")) --nuevo
        else if t1 == t2 
            then (BoolT, DS.singleton (Right $ ""))
            else (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ show t2 
                    ++ "expecting T1 T2 of the same type" ))

binBoolExp :: Type -> Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
binBoolExp BoolT _ BoolT _ = (BoolT, DS.singleton (Right $ ""))
binBoolExp TypeError _ _ _ = (TypeError , DS.singleton (Right $ "")) --nuevo
binBoolExp _ _ TypeError _ = (TypeError , DS.singleton (Right $ "")) -- nuevo
binBoolExp t1 (Lexeme t p) t2 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ show t2 
                    ++ "expecting Bool Bool" ))

numExp :: Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
numExp _ IntT _ = (IntT, DS.singleton (Right $ ""))
numExp _ FloatT _ = (FloatT, DS.singleton (Right $ ""))
numExp _ TypeError _ = (TypeError , DS.singleton (Right $ "")) -- nuevo
numExp (Lexeme t p) t1 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ "expecting Int or Float" ))

boolExp :: Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
boolExp _ BoolT _ = (BoolT, DS.singleton (Right $ ""))
boolExp _ TypeError _ = (TypeError , DS.singleton (Right $ "")) -- nuevo
boolExp (Lexeme t p) t1 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ "expecting Bool" ))

pointExp :: Lexeme Token -> Type -> String -> (Type, DS.Seq(Binnacle))
pointExp _ (PointerT t) _ = (t, DS.singleton (Right $ ""))
pointExp _ TypeError _ = (TypeError , DS.singleton (Right $ "")) --nuevo
pointExp (Lexeme t p) t1 s  = 
    (TypeError , DS.singleton (Left $ "TypeError " ++ show s ++ " " ++ show p 
                    ++ " given " ++ show t1 ++ "expecting Pointer" ))

ifInst :: Type -> Lexeme Token -> Type -> (Type, DS.Seq(Binnacle))
ifInst BoolT _ VoidT            = (VoidT, DS.singleton (Right $ ""))
ifInst TypeError _ _            = (TypeError , DS.singleton (Right $ "")) -- nuevo
ifInst _ _ TypeError            = (TypeError , DS.singleton (Right $ "")) --nuevo
ifInst BoolT (Lexeme t p) t1    = (TypeError, DS.singleton(Left $ "Type Error if " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Void"))
ifInst t1 (Lexeme t p) VoidT    = (TypeError, DS.singleton (Left $ "Type Error if " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Bool" ))

ifElseInst :: Type -> Lexeme Token -> Type -> Type -> (Type, DS.Seq(Binnacle))
ifElseInst BoolT _ VoidT VoidT          = (VoidT, DS.singleton (Right $ ""))
ifElseInst TypeError _ _ _              = (TypeError , DS.singleton (Right $ "")) -- nuevo
ifElseInst _ _ TypeError _              = (TypeError , DS.singleton (Right $ "")) -- nuevo
ifElseInst _ _ _ TypeError              = (TypeError , DS.singleton (Right $ "")) --nuevo
ifElseInst BoolT (Lexeme t p) t1 VoidT  = (TypeError, DS.singleton(Left $ "Type Error if " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Void"))
ifElseInst BoolT (Lexeme t p) VoidT t1  = (TypeError, DS.singleton(Left $ "Type Error if " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Void"))
ifElseInst t1 (Lexeme t p) _ _          = (TypeError, DS.singleton(Left $ "Type Error if " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Bool"))

whileInst :: Type -> Lexeme Token -> Type -> (Type, DS.Seq(Binnacle))
whileInst BoolT _ VoidT         = (VoidT, DS.singleton (Right $ ""))
whileInst TypeError _ _         = (TypeError , DS.singleton (Right $ "")) --nuevo
whileInst _ _ TypeError         = (TypeError , DS.singleton (Right $ "")) --nuevo
whileInst BoolT (Lexeme t p) t1 = (TypeError, DS.singleton(Left $ "Type Error " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Void"))
whileInst t1 (Lexeme t p) _     = (TypeError, DS.singleton(Left $ "Type Error " 
                                    ++ show p ++ "given " ++ show t1 ++ " expecting Bool"))

rangeVef :: Type -> Type -> Type -> (Type, DS.Seq(Binnacle))
rangeVef IntT IntT IntT = (IteratorT, DS.singleton (Right $ ""))
rangeVef TypeError _ _  = (TypeError , DS.singleton (Right $ "")) --nuevo
rangeVef _ TypeError _  = (TypeError , DS.singleton (Right $ "")) --nuevo
rangeVef _ _ TypeError  = (TypeError , DS.singleton (Right $ "")) -- nuevo
rangeVef IntT IntT t1   = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int"))
rangeVef IntT t1 _      = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int"))
rangeVef t1 _ _         = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int"))

forInst :: Type -> Type -> Lexeme Token -> (Type, DS.Seq(Binnacle))
forInst IteratorT VoidT  _          = (VoidT, DS.singleton (Right $ ""))
forInst TypeError _ _               = (TypeError , DS.singleton (Right $ "")) --nuevo
forInst _ TypeError _               = (TypeError , DS.singleton (Right $ "")) --nuevo
forInst IteratorT t1 (Lexeme t p)   = (TypeError, DS.singleton(Left $ "Type Error for "
                                        ++ show p ++ " given " ++ show t1 ++ " expecting Void"))
forInst t1 _  (Lexeme t p)          = (TypeError, DS.singleton(Left $ "Type Error for "
                                        ++ show p ++ " given " ++ show t1 ++ " expecting Int Iterator"))

freeInst :: Type -> Lexeme Token -> (Type,DS.Seq(Binnacle))
freeInst (PointerT _) _     = (VoidT, DS.singleton (Right $ ""))
freeInst TypeError _        =(TypeError , DS.singleton (Right $ "")) --nuevo
freeInst t1 (Lexeme t p)    = (TypeError, DS.singleton(Left $ "Type Error free "
                                ++ show p ++ " given " ++ show t1 ++ " expecting Pointer"))

matchType :: Type -> [Type] -> Type
matchType (FuncT t ts) lts = if ts == lts 
                                then t
                                else TypeError

matchAcc :: Type -> Type -> Lexeme Token -> (Type, DS.Seq(Binnacle))
matchAcc TypeError _ _ = (TypeError , DS.singleton (Right $ "")) -- nuevo
matchAcc _ TypeError _ = (TypeError , DS.singleton (Right $ "")) --nuevo
matchAcc t1 t2 l@(Lexeme TokenAssign p) = 
    if (t1 == t2) 
        then (VoidT,DS.singleton (Right $ "") )
        else (TypeError, DS.singleton(Left $ "Type Error " ++ show p
                        ++ " given " ++ show t2 ++ "expecting " ++ show t1 ))

ifInt :: Type -> Type -> Type
ifInt IntT StringT = StringT 
ifInt IntT FloatT   = FloatT
ifInt _  _          = TypeError

ifFloat :: Type -> Type -> Type
ifFloat FloatT StringT  = StringT 
ifFloat _  _            = TypeError

writeInst :: Type -> (Type, DS.Seq(Binnacle))
writeInst IntT = (VoidT,DS.singleton (Right $ "") )
writeInst FloatT = (VoidT, DS.singleton (Right $ ""))
writeInst StringT = (VoidT, DS.singleton (Right $ ""))
writeInst BoolT = (VoidT, DS.singleton (Right $ ""))
writeInst TypeError = (TypeError, DS.singleton(Right $""))
writeInst t = (TypeError, DS.singleton (Left $ "Type Error in write "))

isTypeT :: Type -> [Lexeme Token] -> Zipper-> (Type, DS.Seq(Binnacle))
isTypeT t ls z = case t of
    TypeT s     -> case lookupS s z of
        Just ((Entry ty pos sz o),sc) -> findField ty ls z
        Nothing                  ->  (TypeError, DS.singleton (Left $ "Type Error not defined " 
                                    ++ show t))
    TypeError   -> (TypeError, DS.singleton (Right $ "")) --nuevo
    _           -> (TypeError, DS.singleton (Left $ "Type Error not defined " --nuevo
                                    ++ show t))

findField :: Type -> [Lexeme Token] -> Zipper -> (Type, DS.Seq(Binnacle))
findField t [l@(Lexeme (TokenIdent s) p) ] z    = 
    if (fst $ isStruct t z)
        then case (DMap.lookup s (snd $ isStruct t z)) of
            Just  ty            -> (ty, DS.singleton (Right $ ""))
            Nothing             -> (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " not defined field " ++ s))
        else (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " given " ++ show t 
                                    ++ " expecting Struct or Union"))
findField t (l@(Lexeme (TokenIdent s) p):ls) z = 
    if (fst $ isStruct t z)
        then case (DMap.lookup s (snd $ isStruct t z)) of
            Just (ty)   -> 
                if (fst $ isStruct ty z)
                        then (isTypeT ty ls z)
                        else (TypeError, DS.singleton (Left $ "Type Error "
                                ++ show (pos l) ++ " given " ++ show ty 
                                ++ " expecting Struct or Union")) 
            Nothing             -> (TypeError, DS.singleton (Left $ "Type Error " -- entra aqui
                                        ++ show (pos l) ++ " not defined " ++ show t)) 
        else (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " given " ++ show t 
                                    ++ " expecting Struct or Union"))

isStruct :: Type -> Zipper -> (Bool, DMap.Map String Type)
isStruct t z = case t of
        UnionT m    -> (True, m)
        StructT m   -> (True, m)
        TypeT   s   -> case (lookupS s z) of
                            Just ((Entry ty p sz o),sc) -> isStruct ty z 
                            Nothing         -> (False, DMap.empty)
        t1          -> (False, DMap.empty)


instruc :: [Type] -> Type 
instruc ts = if (all (==VoidT) ts) 
                then VoidT
                else TypeError

typeT :: Type -> Bool
typeT (TypeT s) = True
typeT _       = False

instrucS :: Type -> Type 
instrucS VoidT = VoidT
instrucS _     = TypeError

isNum :: Type -> Bool
isNum IntT      = True
isNum _         = False

allNum :: [Type] -> Bool
allNum ts = if (all isNum ts)
                then True
                else False

isArray :: Type -> [Type] -> (Type,DS.Seq(Binnacle))
isArray a@(ArrayT t) []  = (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show a ++ " expecting a basic type"))
isArray (ArrayT t) (ty:ts) = if allNum (ty:ts)
                    then isArray t ts
                    else (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show ts ++ "expecting list of Int fields"))
isArray TypeError _ = (TypeError , DS.singleton (Right $ "")) --nuevo
isArray t          ts = if null ts
                    then (t, DS.singleton (Right $ ""))
                    else (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show ts ++ "expecting list of Int fields"))

isTypeVoid :: Type -> Type
isTypeVoid VoidT = VoidT
isTypeVoid TypeError = TypeError

}   