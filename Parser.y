{

-------------- Parser para el lenguaje de programación Pandora -----------------

module Parser 
    ( parse
    ) where

import Lexer
import Instructions
import Expression
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

Program : Declarations Main "EOF"  { % do
                                    st <- get
                                    put $ State (syt st) (srt st) (AST (snd $2))
                                    return (instruc ((fst $2):[$1]), AST (snd $2)) }             
       | Main "EOF"                { % do
                                    st <- get
                                    put $ State (syt st) (srt st) (AST (snd $1))
                                    return  (fst $1, AST (snd $1)) } 

Main : begin OS Insts CS end  { % return (fst $3, (reverse (snd $3))) } 

Declaration:  FuncDec OS Insts CS end CS    {% do
                                                st <- get
                                                put $ State (insertInsF (snd $ snd $1) (snd $3) (syt st)) (srt st) (ast st)
                                                return (fst $3) } 
            | struct id has StructObjs ";" end         { % do 
                                                        st <- get
                                                        tell (snd (doInsertS (makeStruct $1 $4 (syt st)) ((syt st),DS.empty) $2))
                                                        put $ State (fst (doInsertS (makeStruct $1 $4 (syt st)) ((syt st),DS.empty) $2)) (srt st) (ast st)  
                                                        return VoidT}
            | union id like StructObjs ";" end          { % do 
                                                        st <- get
                                                        tell (snd (doInsertS (makeStruct $1 $4 (syt st)) ((syt st),DS.empty) $2))
                                                        put $ State (fst(doInsertS (makeStruct $1 $4 (syt st)) ((syt st),DS.empty) $2)) (srt st) (ast st)
                                                        return VoidT  }
            | Dec                                       { % return (fst $1) }
            | Assign                                    { % return (fst $1) } 

StructObjs : StructOb                   { $1 }
            | StructObjs ";" StructOb   { $1 ++ $3 }

StructOb : Type ":" ListId { [(x,y) | x <- $3,  y <- [(makeBtype $1)]] }
            | array of Type Dimen ":" ListId { [(x,y) | x <- $6,  y <- [(makeArray $4 (makeBtype $3))] ] }
            | Type Astk id {[($3, (makePointer $2 (makeBtype $1)))]}

FuncDec : TypeFunc OS "(" Param ")"  {% do 
                                        st <- get
                                        tell (snd (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) $4) ((syt st),DS.empty) (snd $1)))
                                        put $ State (fst (doInsertFun (makeObj (fst(fst $1)) (snd(fst $1)) $4) ((syt st),DS.empty) (snd $1))) (srt st) (ast st)
                                        return (fst $1,($4,snd $1)) }
        
TypeFunc :  Type ":" func id    {% do 
                                   st <- get
                                   tell( snd (doInsertF (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4))
                                   put $ State (fst (doInsertF (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4)) (srt st) (ast st)
                                   return (($3,makeBtype $1),$4) } 
        | Type ":" proc id {% do 
                              st <- get
                              tell( snd (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4))
                              put $ State (fst (doInsert (makeObj $3 (makeBtype $1) []) ((syt st),DS.empty) $4)) (srt st) (ast st)
                              return (($3,makeBtype $1),$4)} 

OS: {- Lambda -} { % do 
                     st <- get 
                     put $ State (openScope (syt st)) (srt st) (ast st)
                 }

CS: {- Lambda -} { % do 
                     st <- get 
                     put $ State (closeScope (syt st)) (srt st) (ast st)
                 }

Declarations : Declaration { % return (instrucS $1) }
    | Declarations Declaration  { % return (instruc ($2:[$1])) }

Dec : Type ":" ListId                      { % do 
                                            st <- get 
                                            tell (snd (foldl (doInsert (makeBtype $1)) ((syt st),DS.empty)  $3))
                                            put $ State (fst (foldl (doInsert (makeBtype $1)) ((syt st),DS.empty)  $3)) (srt st) (ast st)
                                            return (VoidT, None)}
    | array of Type Dimen ":" ListId       { % do
                                            st <- get
                                            tell (snd (foldl (doInsert (makeArray $4 (makeBtype $3))) ((syt st),DS.empty) $6))
                                            put $ State (fst(foldl (doInsert (makeArray $4 (makeBtype $3))) ((syt st),DS.empty) $6)) (srt st) (ast st)
                                            return (VoidT, None) } 
    | Type Astk id  { % do 
                        st <- get 
                        tell (snd (doInsert (makePointer $2 (makeBtype $1)) ((syt st),DS.empty) $3))
                        put $ State (fst (doInsert (makePointer $2 (makeBtype $1)) ((syt st),DS.empty) $3)) (srt st) (ast st)
                        return (VoidT, None) 
                        }

Astk : "*"     {% return 1}
    | Astk "*" {% return ($1 + 1)}


Param: {- lambda -}     { % return [] } 
        | Params        { % return $1 } 

Params: Type ":" id     { % do
                            st <- get
                            tell (snd (doInsert (makeBtype $1) ((syt st),DS.empty) $3))
                            put $ State (fst (doInsert (makeBtype $1) ((syt st),DS.empty) $3)) (srt st) (ast st)
                            return [(makeBtype $1)]} 
        | array of Type Dimen ":" id    {% do
                                            st <- get
                                            tell (snd (doInsert (makeArray $4 (makeBtype $3)) ((syt st),DS.empty) $6))
                                            put $ State (fst (doInsert (makeArray $4 (makeBtype $3)) ((syt st),DS.empty) $6)) (srt st) (ast st)
                                            return [(makeBtype $3)]} 
        | var Type ":" id   { % do
                                st <- get
                                tell (snd (doInsert (makeBtype $2) ((syt st),DS.empty) $4))
                                put $ State (fst (doInsert (makeBtype $2) ((syt st),DS.empty) $4)) (srt st) (ast st)
                                return [(makeBtype $2)]} 
        | var array of Type Dimen ":" id    { % do
                                                st <- get
                                                tell (snd (doInsert (makeArray $5 (makeBtype $4)) ((syt st),DS.empty) $7))
                                                put $ State (fst (doInsert (makeArray $5 (makeBtype $4)) ((syt st),DS.empty) $7)) (srt st) (ast st)
                                                return [(makeBtype $4)]} 
        | Params "," var Type ":" id    {% do
                                            st <- get
                                            tell (snd (doInsert (makeBtype $4) ((syt st),DS.empty) $6))
                                            put $ State (fst (doInsert (makeBtype $4) ((syt st),DS.empty) $6)) (srt st) (ast st)
                                            return ((makeBtype $4):$1)} 
        | Params "," var array of Type Dimen ":" id     {% do
                                                            st <- get
                                                            tell (snd (doInsert (makeArray $7 (makeBtype $6)) ((syt st),DS.empty) $9))
                                                            put $ State (fst (doInsert (makeArray $7 (makeBtype $6)) ((syt st),DS.empty) $9)) (srt st) (ast st)
                                                            return ((makeBtype $6):$1)} 
        | Params "," Type ":" id    { % do
                                        st <- get
                                        tell (snd (doInsert (makeBtype $3) ((syt st),DS.empty) $5))
                                        put $ State (fst (doInsert (makeBtype $3) ((syt st),DS.empty) $5)) (srt st) (ast st)
                                        return ((makeBtype $3):$1)} 
        | Params "," array of Type Dimen ":" id     { % do
                                                        st <- get
                                                        tell (snd (doInsert (makeArray $6 (makeBtype $5)) ((syt st),DS.empty) $8))
                                                        put $ State (fst (doInsert (makeArray $6 (makeBtype $5)) ((syt st),DS.empty) $8)) (srt st) (ast st)
                                                        return ((makeBtype $5):$1) }

Type : intT     { $1 } 
    | floatT    { $1 }
    | stringT   { $1 }
    | charT     { $1 }
    | boolT     { $1 }
    | voidT     { $1 }
    | id        { $1 }

Dimen : "[" int "]"             { % return [$2] }
        | Dimen "[" int "]"     { % return ($3:$1) } 

Values : true               { (BoolT, BoolL True (pos $1)) }
    | false                 { (BoolT, BoolL False (pos $1)) }
    | null                  { (VoidT, VoidL (pos $1)) }
    | int                   { (IntT , IntL (getTkInt $1) (pos $1)) }
    | float                 { (FloatT, FloatL (getTkFloat $1) (pos $1)) }
    | char                  { (CharT, CharL (getTkChar $1) (pos $1)) }

Exp : Values                { % return $1 }
    | id                    { % do
                                    st <- get
                                    tell (snd (findId $1 (syt st)))
                                    case DS.index (snd (findId $1 (syt st))) 0 of
                                        Left _ -> return ((typeToken $1 (syt st)), NoneE)
                                        _      -> return ((typeToken $1 (syt st)), IdL (getTkID $1) (pos $1)) }
    | Exp "+" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "+"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "+")), ExpBin Plus (snd $1) (snd $3) (pos $2)) }
    | Exp "-" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "-"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "-")), ExpBin Minus (snd $1) (snd $3) (pos $2)) }
    | Exp "/" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "/"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "/")), ExpBin Slash (snd $1) (snd $3) (pos $2)) }
    | Exp "^" Exp           { % do  
                                    st <- get -- No estoy seguro cuales serian los tipos
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "^"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "^")), ExpBin Power (snd $1) (snd $3) (pos $2)) }
    | Exp "*" Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "*"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "*")), ExpBin Mul (snd $1) (snd $3) (pos $2)) }
    | Exp div Exp           { % do 
                                    st <- get --Creo que oslo serian Enteros
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "div"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "div")), ExpBin Div (snd $1) (snd $3) (pos $2)) }
    | Exp mod Exp           { % do 
                                    st <- get 
                                    tell (snd (binNumExp (fst $1) $2 (fst $3) "mod"))
                                    return ((fst (binNumExp (fst $1) $2 (fst $3) "mod")), ExpBin Mod (snd $1) (snd $3) (pos $2)) }
    | Exp ">" Exp           { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) ">"))
                                    return ((fst (relExp (fst $1) $2 (fst $3) ">")), ExpBin Gt (snd $1) (snd $3) (pos $2)) }
    | Exp ">=" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) ">="))
                                    return ((fst (relExp (fst $1) $2 (fst $3) ">=")), ExpBin GEt (snd $1) (snd $3) (pos $2)) }
    | Exp "<" Exp           { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) "<"))
                                    return ((fst (relExp (fst $1) $2 (fst $3) "<")), ExpBin Lt (snd $1) (snd $3) (pos $2)) }
    | Exp "<=" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) "<="))
                                    return ((fst (relExp (fst $1) $2 (fst $3) "<=")), ExpBin LEt (snd $1) (snd $3) (pos $2)) }
    | Exp "==" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) "=="))
                                    return ((fst (relExp (fst $1) $2 (fst $3) "==")), ExpBin Equal (snd $1) (snd $3) (pos $2)) }
    | Exp "/=" Exp          { % do 
                                    st <- get 
                                    tell (snd (relExp (fst $1) $2 (fst $3) "/="))
                                    return ((fst (relExp (fst $1) $2 (fst $3) "/=")), ExpBin Inequal (snd $1) (snd $3) (pos $2)) }
    | Exp and Exp           { % do 
                                    st <- get 
                                    tell (snd (binBoolExp (fst $1) $2 (fst $3) "and"))
                                    return ((fst (binBoolExp (fst $1) $2 (fst $3) "and")), ExpBin And (snd $1) (snd $3) (pos $2)) }
    | Exp or Exp            { % do 
                                    st <- get 
                                    tell (snd (binBoolExp (fst $1) $2 (fst $3) "or"))
                                    return ((fst (binBoolExp (fst $1) $2 (fst $3) "or")), ExpBin And (snd $1) (snd $3) (pos $2)) }
    | "-" Exp   %prec NEG   { % do 
                                    tell (snd (numExp $1 (fst $2) "-"))
                                    return ((fst (numExp $1 (fst $2) "-")), ExpUna Minus (snd $2) (pos $1)) }
    | not Exp   %prec NEG   { % do 
                                    tell (snd (numExp $1 (fst $2) "not"))
                                    return ((fst (numExp $1 (fst $2) "not")), ExpUna Not (snd $2) (pos $1)) }
    | "->" Exp  %prec NEG   { % do 
                                    tell (snd (pointExp $1 (fst $2) "->"))
                                    return ((fst (pointExp $1 (fst $2) "->")), ExpUna Arrow (snd $2) (pos $1)) }
    | Accesor               { % return $1 }
    | CFunctions            { % return $1 }
    | "(" Exp ")"           { % return $2 }
    | string                { % do 
                                st <- get
                                put $ State (syt st) (doInsertStr StringT (srt st) $1) (ast st)
                                return (StringT, StringL (getTkID $1) (pos $1))
                                }
    |FuncCall               { % return $1 } 

Assign : id "=" Exp  ";"        { % do 
                                    st <- get 
                                    tell (snd (findIdA $1 (fst $3) (syt st)))
                                    return (fst (findIdA $1 (fst $3) (syt st)), AsngL (IdL (getTkID $1) (pos $1)) (snd $3) (pos $2)) }

        | Accesor "=" Exp ";"   { % do
                                    tell (snd (matchAcc (fst $1) (fst $3) $2))
                                    return (fst(matchAcc (fst $1) (fst $3) $2), AsngL (snd $1) (snd $3) (pos $2)) }

ListId : id                 { [$1] }
        | ListId "," id     {  $3 : $1 }

Accesor : id Arrays { % do 
                        st <- get 
                        tell (snd(isArray $1 (typeToken $1 (syt st)) (fst $ unzip $2)))
                        return(fst(isArray $1 (typeToken $1 (syt st)) (fst $ unzip $2)), AccsA (IdL (getTkID $1) (pos $1)) (snd $ unzip $2) (pos $1))}
        | id Accs  
        { % do 
            st <- get 
            tell (snd (isTypeT $1 (typeToken $1 (syt st)) (reverse $ fst $ unzip $2) (syt st)))
            return (fst(isTypeT $1 (typeToken $1 (syt st)) (reverse $ fst $ unzip $2) (syt st)), AccsS (IdL (getTkID $1) (pos $1)) (snd $ unzip $2) (pos $1))}

Accs: Acc       { % return [$1] }
    | Accs Acc  { % return ($2:$1) }

Acc : "." id        { % return ($2, IdL (getTkID $2) (pos $2)) }

Arrays : Array        { % return [$1] }
       | Arrays Array { % return ($2:$1) }

Array : "[" int "]"   { % return (IntT, IntL (getTkInt $2) (pos $2)) }

FuncCall : id "(" Fields ")" { % do 
                                    st <- get 
                                    tell (snd (findFunc $1 (fst $ unzip $3) (syt st)))
                                    return (fst (findFunc $1 (fst $ unzip $3) (syt st)), FCall (IdL (getTkID $1) (pos $1)) (snd $ unzip $3) (pos $1)) }

Fields : {- lambda -}       { % return [] }
        | Exp               { % return ([$1]) }
        | Fields "," Exp    { % return ($3:$1) }

CFunctions : inttostr "(" Exp ")"   { % return ((ifInt (fst $3) StringT), CFCall (IdL (show $ token $1) (pos $1)) (snd $3) (pos $1)) } 
            | flotostr "(" Exp ")"  { % return ((ifFloat (fst $3) StringT), CFCall (IdL (show $ token $1) (pos $1)) (snd $3) (pos $1)) } 
            | inttoflo "(" Exp ")"  { % return ((ifInt (fst $3) FloatT), CFCall (IdL (show $ token $1) (pos $1)) (snd $3) (pos $1)) } 

Insts : Inst            { % return (instrucS (fst $1), [snd $1]) }
        | Insts Inst    { % return (instruc ((fst $2):[fst $1]), (snd $2):(snd $1)) }


InstA : read Exp ";"    { % return (fst $2, ReadL (snd $2) (pos $1)) } 

Inst : InstA            { % return $1  }
    | Assign            { % return $1 } 
    | Dec ";"           { % return $1 }
    | Write             { % return $1 }
    | Return            { % return $1 }
    | free Exp ";"      { % do  
                            tell (snd (freeInst (fst $2) $1))
                            return (fst (freeInst (fst $2) $1), FreeL (snd $2) (pos $1)) } 
    | InstB             { % return $1 }

InstB: If               { % return $1 }
    | While             { % return $1 }
    | Repeat            { % return $1 }
    | For               { % return $1 }

Return : return Exp ";"     { % return (fst $2, ReturnL (snd $2) (pos $1)) } 

Write : write Exp ";"       { % do 
                                tell (snd (writeInst $1 (fst $2)))
                                return (fst (writeInst $1 (fst $2)), WriteL (snd $2) (pos $1)) } 

If : if "(" Exp ")" then Block  { % do 
                                    tell (snd (ifInst (fst $3) $1 (fst $6)))
                                    return (fst (ifInst (fst $3) $1 (fst $6)), IfL (snd $3) (snd $6) (pos $1)) } 
    | if "(" Exp ")" then Block else Insts end  {% do 
                                                    tell (snd (ifElseInst (fst $3) $1 (fst $6) (fst $8)))
                                                    return (fst (ifElseInst (fst $3) $1 (fst $6) (fst $8)), IfteL (snd $3) (snd $6) (snd $8) (pos $1)) }

For : for OS "(" Range ")" do Block CS  
{ % do 
    st <- get 
    tell (snd (forInst (fst $4) (fst $7) $1))
    return (fst (forInst (fst $4) (fst $7) $1), ForL (head $ snd $4) (head $ tail $ snd $4) (last $ snd $4) (snd $7) (pos $1)) } 

Range : It from Exp to Exp with Exp  { % do 
                                        st <- get 
                                        tell (snd (rangeVef $2 (fst $3) (fst $5) (fst $7)))
                                        return (fst (rangeVef $2 (fst $3) (fst $5) (fst $7)), [(snd $3), (snd $5), (snd $7)]) }
It : id { % do 
                st <- get
                put $ State (fst $ doInsert IteratorT ((syt st),DS.empty) $1) (srt st) (ast st)
                tell (snd (doInsert IteratorT ((syt st),DS.empty) $1)) }

While : while "(" Exp ")" do Block  { % do
                                        st <- get
                                        tell (snd (whileInst (fst $3) $1 (fst $6)))
                                        return (fst (whileInst (fst $3) $1 (fst $6)), WhileL (snd $3) (snd $6) (pos $1)) }

Repeat : repeat OS Insts until Exp CS  { % do
                                        st <- get
                                        tell (snd (whileInst (fst $5) $1 (fst $3)))
                                        return (fst (whileInst (fst $5) $1 (fst $3)), RepeatL (snd $3) (snd $5) (pos $1)) }

Block : OS Insts end CS { % return (fst $2, snd $2) } 

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)


doInsert:: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsert VoidT (z,_) l@(Lexeme (TokenIdent s) p) = 
     (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                    " can't be declared as void")))

doInsert (TypeT t) (z,_) l@(Lexeme (TokenIdent s) p) =
    case lookupS t z of
        Nothing -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " " ++ show p ++
                                      " not declared ")))
        Just ((Entry st pos sz o),_) -> 
            case st of
                StructT _ ->  
                    case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p sz (padding (TypeT t) (offScope z))) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                      " already declared " ++ show pos)))
                UnionT _ -> case lookupS' s z of
                        Nothing -> (insertS s (Entry (TypeT t) p sz (padding (TypeT t) (offScope z))) z, DS.singleton(Right $ ""))
                        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                      " already declared " ++ show pos)))
                _ -> (z, DS.singleton (Left $ ("Type " ++ show t ++ " " ++ show p ++
                                      " not declared ")))
doInsert t (z,_) l@(Lexeme (TokenIdent s) p) = 
    case lookupS' s z of
        Nothing -> (insertS s (Entry t p (typeSize' t z) (padding t (offScope z))) z, DS.singleton(Right $ ""))
        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                      " already declared " ++ show pos)))

--Funcion para agregar la funcion y procedimiento sin el offset ya que no lleva
doInsertF:: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsertF t (z,_) l@(Lexeme (TokenIdent s) p) = 
    case lookupS' s z of
        Nothing -> (insertS s (Entry t p (typeSize' t z) 0) z, DS.singleton(Right $ ""))
        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                      " already declared " ++ show pos)))


doInsertS :: (Type, Int) -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsertS (t, i) (z,_) l@(Lexeme (TokenIdent s) p) = 
    case lookupS' s z of
        Nothing -> (insertS s (Entry t p i 0) z, DS.singleton(Right $ ""))
        Just (Entry typ pos sz o) -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++
                                      " already declared " ++ show pos)))

typeSize' (ArrayT d t) z = d * typeSize' t z
typeSize' (FuncT t ts ast) z = typeSize' t z
typeSize' (ProcT t ts ast) z = typeSize' t z
typeSize' (TypeT s) z    = sm
    where (Entry t p sm o) = fst $ fromJust $ lookupS s z
typeSize' t z = typeSize t 

structSize m z = DMap.foldl (structS z) 0 m

structS z n (Entry (TypeT s) p sz off) = n + sm
    where (Entry t p sm o) = fst $ fromJust $ lookupS s z
structS z n (Entry t p sz off) = n + typeSize' t z

unionSize m z = DMap.foldl (unionS z) 0 m

unionS z n (Entry (TypeT s) p sz off) = if n > sm then n else sm
    where (Entry t p sm o) = fst $ fromJust $ lookupS s z
unionS z n (Entry t p sz off) = if n > typeSize' t z then n else typeSize' t z  

doInsertFun :: Type -> (Zipper,DS.Seq(Binnacle)) -> Lexeme Token -> (Zipper, DS.Seq(Binnacle))
doInsertFun t (z,_) l@(Lexeme (TokenIdent s) p) = 
    (fromJust (goDown (insertS s (Entry t p size offset) (fromJust(goBack z)))), DS.singleton(Right $ ""))
        where (Entry ty pos size offset) = fst $ fromJust $ lookupS s z

doInsertStr:: Type -> Zipper -> Lexeme Token -> Zipper
doInsertStr t z l@(Lexeme (TokenString s) p) = 
    case lookupS' s z of
        Nothing -> insertS s (Entry t p 0 0) z
        _ -> z
 
findId :: Lexeme Token -> Zipper -> (Zipper, DS.Seq(Binnacle))
findId l@(Lexeme (TokenIdent s) p) z =  case lookupS s z of
                Nothing -> (z, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++ " is not defined")))
                Just v  -> (z, DS.singleton (Right $ ""))

findIdA :: Lexeme Token -> Type -> Zipper -> (Type, DS.Seq(Binnacle))
findIdA l@(Lexeme (TokenIdent s) p) ty z =  case lookupS s z of
                Nothing -> (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++ " is not defined")))
                Just ((Entry t p sz o),scp)  -> if t == IteratorT 
                                            then (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " " ++ show p ++ " can't be assigned")))
                                            else if t == ty 
                                                then (VoidT, DS.singleton (Right $ ""))
                                                else (TypeError, DS.singleton (Left $ ("TypeError " ++ show s ++ " " ++ show p ++ " given " ++ show ty 
                                                    ++ " expecting " ++ show t )))

findFunc :: Lexeme Token -> [Type] -> Zipper -> (Type, DS.Seq(Binnacle))
findFunc l@(Lexeme (TokenIdent s) p) ts z =  case lookupS s z of
                Nothing                 -> (TypeError, DS.singleton (Left $ ("Variable " ++ show s ++ " " 
                                            ++ show p ++ " is not defined")))
                Just ((Entry t@(FuncT ty lts ast) pos sz o),scp)  -> 
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

rangeVef :: Lexeme Token -> Type -> Type -> Type -> (Type, DS.Seq(Binnacle))
rangeVef l IntT IntT IntT = (IteratorT, DS.singleton (Right $ ""))
rangeVef l TypeError _ _  = (TypeError , DS.singleton (Right $ "")) --nuevo
rangeVef l _ TypeError _  = (TypeError , DS.singleton (Right $ "")) --nuevo
rangeVef l _ _ TypeError  = (TypeError , DS.singleton (Right $ "")) -- nuevo
rangeVef l IntT IntT t1   = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int in for instruction " ++ show (pos l)))
rangeVef l IntT t1 _      = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int in for instruction " ++ show (pos l)))
rangeVef l t1 _ _         = (TypeError, DS.singleton(Left $ "Type Error given " 
                            ++ show t1 ++ " expecting Int in for instruction " ++ show (pos l)))

forInst :: Type -> Type -> Lexeme Token -> (Type, DS.Seq(Binnacle))
forInst IteratorT VoidT  _          = (VoidT, DS.singleton (Right $ ""))
forInst TypeError _ _               = (TypeError , DS.singleton (Right $ ""))
forInst _ TypeError _               = (TypeError , DS.singleton (Right $ "")) 
forInst IteratorT t1 (Lexeme t p)   = (TypeError, DS.singleton(Left $ "Type Error for "
                                        ++ show p ++ " given " ++ show t1 ++ " expecting Void"))
forInst t1 _  (Lexeme t p)          = (TypeError, DS.singleton(Left $ "Type Error for "
                                        ++ show p ++ " given " ++ show t1 ++ " expecting Int Iterator"))

freeInst :: Type -> Lexeme Token -> (Type,DS.Seq(Binnacle))
freeInst (PointerT _) _     = (VoidT, DS.singleton (Right $ ""))
freeInst TypeError _        =(TypeError , DS.singleton (Right $ "")) 
freeInst t1 (Lexeme t p)    = (TypeError, DS.singleton(Left $ "Type Error free "
                                ++ show p ++ " given " ++ show t1 ++ " expecting Pointer"))

matchType :: Type -> [Type] -> Type
matchType (FuncT t ts ast) lts = if ts == lts 
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

writeInst :: Lexeme Token -> Type -> (Type, DS.Seq(Binnacle))
writeInst l IntT = (VoidT,DS.singleton (Right $ "") )
writeInst l FloatT = (VoidT, DS.singleton (Right $ ""))
writeInst l StringT = (VoidT, DS.singleton (Right $ ""))
writeInst l BoolT = (VoidT, DS.singleton (Right $ ""))
writeInst l TypeError = (TypeError, DS.singleton(Right $""))
writeInst l t = (TypeError, DS.singleton (Left $ "Type Error in write instruction " ++ show (pos l)))

isTypeT :: Lexeme Token -> Type -> [Lexeme Token] -> Zipper-> (Type, DS.Seq(Binnacle))
isTypeT l t ls z = case t of
    TypeT s     -> case lookupS s z of
        Just ((Entry ty pos sz o),sc) -> findField ty ls z
        Nothing                  ->  (TypeError, DS.singleton (Left $ "Type Error not defined " 
                                    ++ show t ++ " " ++ show (pos l)))
    TypeError   -> (TypeError, DS.singleton (Right $ "")) --nuevo
    _           -> (TypeError, DS.singleton (Left $ "Type Error not defined " --nuevo
                                    ++ show t ++ " " ++ show (pos l)))

findField :: Type -> [Lexeme Token] -> Zipper -> (Type, DS.Seq(Binnacle))
findField t [l@(Lexeme (TokenIdent s) p) ] z    = 
    if (fst $ isStruct t z)
        then case (DMap.lookup s (snd $ isStruct t z)) of
            Just (Entry ty p zs off) -> (ty, DS.singleton (Right $ ""))
            Nothing             -> (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " not defined field " ++ s))
        else (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " given " ++ show t 
                                    ++ " expecting Struct or Union"))
findField t (l@(Lexeme (TokenIdent s) p):ls) z = 
    if (fst $ isStruct t z)
        then case (DMap.lookup s (snd $ isStruct t z)) of
            Just (Entry ty p sz off)   -> 
                if (fst $ isStruct ty z)
                        then (isTypeT l ty ls z)
                        else (TypeError, DS.singleton (Left $ "Type Error "
                                ++ show (pos l) ++ " given " ++ show ty 
                                ++ " expecting Struct or Union")) 
            Nothing             -> (TypeError, DS.singleton (Left $ "Type Error " -- entra aqui
                                        ++ show (pos l) ++ " not defined " ++ show t)) 
        else (TypeError, DS.singleton (Left $ "Type Error "
                                    ++ show (pos l) ++ " given " ++ show t 
                                    ++ " expecting Struct or Union"))

isStruct :: Type -> Zipper -> (Bool, DMap.Map String Entry)
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

isArray :: Lexeme Token -> Type -> [Type] -> (Type,DS.Seq(Binnacle))
isArray (Lexeme (TokenIdent s) p) a@(ArrayT d t) []  
                        = (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show a ++ " expecting a basic type in array " ++ s 
                        ++ " " ++ show p))
isArray l@(Lexeme (TokenIdent s) p)(ArrayT d t) (ty:ts) 
                    = if allNum (ty:ts)
                        then isArray l t ts
                        else (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show ts ++ "expecting list of Int fields in array " ++ s 
                        ++ " " ++ show p))
isArray (Lexeme (TokenIdent s) p) TypeError _ 
                    = (TypeError , DS.singleton (Right $ ""))
isArray (Lexeme (TokenIdent s) p) t ts = 
                    if null ts
                        then (t, DS.singleton (Right $ ""))
                        else (TypeError, DS.singleton (Left $ "Type Error given " 
                        ++ show ts ++ "expecting list of Int fields in array " ++ s 
                        ++ " " ++ show p))

isTypeVoid :: Type -> Type
isTypeVoid VoidT = VoidT
isTypeVoid TypeError = TypeError

makeStruct :: Lexeme t -> [(Lexeme Token, Type)] -> Zipper -> (Type, Int)
makeStruct lex list z = case (token lex) of
    TokenStruct -> (StructT $ DMap.fromList m, s)
        where (m , s) = (foldl (makeEntry z) ([],0) list)
    TokenUnion -> (UnionT $ DMap.fromList m, s)
        where (m , s) = (foldl (makeUnion z) ([],0) list)


makeEntry :: Zipper -> ([(String, Entry)], Int) -> (Lexeme Token, Type) -> ([(String, Entry)],Int)
makeEntry z (l,n) (Lexeme (TokenIdent s) p, t) = ((s,(Entry t p (typeSize' t z) (padding t n))): l, padding t (n + (typeSize' t z)))

makeUnion :: Zipper -> ([(String, Entry)], Int) -> (Lexeme Token, Type) -> ([(String, Entry)],Int)
makeUnion z (l,n) (Lexeme (TokenIdent s) p, t) = ((s,(Entry t p (typeSize' t z) 0 )): l,if n > (typeSize' t z) then n else (typeSize' t z))

insertInsF :: Lexeme Token -> [Instructions] -> Zipper -> Zipper
insertInsF (Lexeme (TokenIdent s) p) l z = case (lookupS s z) of
        Just (Entry (FuncT t lt _) pos i1 i2, sc) -> insertS s (Entry (FuncT t lt (AST l)) pos i1 i2) z
        Just (Entry (ProcT t lt _) pos i1 i2, sc) -> insertS s (Entry (ProcT t lt (AST l)) pos i1 i2) z

}   