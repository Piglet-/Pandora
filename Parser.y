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

%monad      { RWS String [String] (Zipper,Zipper) }
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

Declaration: func id "(" Param ")" ":" Type Insts end   { % return () } -- meter el id con type func 
            | proc id "(" Param ")" ":" Type Insts end  { % return () }
            | struct id has Decs end                    { % return () }
            | union id like Decs end                    { % return () }
            | Dec                                       { % return () }
            | Assign                                    { % return () } -- ignorar de momento

Declarations : Declaration { % return () }
    | Declarations Declaration  { % return () }

Decs : Dec         { % return () }
    | Decs Dec     { % return () }

-- y la declaracion de apuntadores?
Dec : ListId ":" Type                   { % return () } 
                                            --do 
                                            --(z, z') <- get 
                                            --put (fmap (doInsert (makeBtype $3) z) $1, z')}
    --| ListId ":" array of Type Dimen    { % return () } -- igual al anterior pero el type es array

-- abrir un scope e insertar los parametros
Param: {- lambda -}     { % return () } 
        | Params        { % return () } -- abrir el nuevo scope, guardar

Params: Dec                  	 { % return () }
        | var Dec	          	 { % return () }
        | Params "," var Dec     { % return () }
        | Params "," Dec     	 { % return () }

Type : intT     { $1 } 
    | floatT    { $1 }
    | stringT   { $1 }
    | charT     { $1 }
    | boolT     { $1 }
    | voidT     { $1 }

Dimen : "[" Exp "]"             { % return () }
        | Dimen "[" Exp "]"     { % return () }

Exps : Exp          { % return () }
    | Exps "," Exp  { % return () }

Values : true               { $1 }
    | false                 { $1 }
    | null                  { $1 }
    | id                    { $1 }
    | int                   { $1 }
    | float                 { $1 }
    | char                  { $1 }
    | string                { $1 }

Exp : Values                { % return () }
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

Assign : id "=" Exp  ";"        { % return () }
        | id "=" InstA          { % return () }
        | Accesor "=" Exp ";"   { % return () }

ListId : id                 { DS.singleton $1 }
        | ListId "," id     { $1 DS.|> $3 }

Accesor : id Accs { % return () }

Accs: Acc       { % return () }
    | Accs Acc  { % return () }

Acc : "." id        { % return () }
    | "[" Exp "]"   { % return () }

FuncCall : id "(" Fields ")" { % return () }

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
InstA :  new ListId ";" { % return () }
    | read Exp ";"      { % return () }
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

For : for "(" id Range ")" do Block  { % return () }

Range : from Exp to Exp with Exp  { % return () }

While : while "(" Exp ")" do Block  { % return () }

Repeat : repeat Insts until Exp  { % return () }

Block : Insts end  { % return () } -- abrir y cerrar el scope

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)


-- en lugar de lexeme token, DS.seq (Lexeme Token) y hacer
-- fold que inserte en el zipper.
doInsert:: Type -> Zipper -> Lexeme Token -> Zipper
doInsert t z l = insertS (show $ token l) (newEntry l t) z
 
-- nota -------> FOLDL <---------- 
newEntry :: Lexeme Token -> Type -> Entry
newEntry l t = Entry t (pos l)

}