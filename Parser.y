{

-------------- Parser para el lenguaje de programación Pandora -----------------

module Parser 
    ( parse
    ) where

import Lexer
import Control.Monad.RWS
import SymbolTable

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

Program : Declarations Main "EOF"  {% return () }               
	   | Main "EOF"                { % return ()}

Main : begin Insts end  {% return () }

Declaration: func id "(" Param ")" ":" Type Insts end   { % return ()}
            | proc id "(" Param ")" ":" Type Insts end  { % return ()}
            | struct id has Decs end                    { % return ()}
            | union id like Decs end                    { % return ()}
            | Dec                                       { % return ()}
            | Assign                                    { % return ()}

Declarations : Declaration {% return () }
    | Declarations Declaration  {% return () }

Decs : Dec         { % return ()}
    | Decs Dec     { % return ()}

Dec : ListId ":" Type                   { % return ()}
    | ListId ":" array of Type Dimen    { % return ()}

Param: {- lambda -}     {% return () }
        | Params        {% return () }

Params: Dec                  	 {% return () }
        | var Dec	          	 {% return () }
        | Params "," var Dec     { % return ()}
        | Params "," Dec     	 { % return ()}

Type : intT     { $1 } 
    | floatT    { $1 }
    | stringT   { $1 }
    | charT     { $1 }
    | boolT     { $1 }
    | voidT     { $1 }

Dimen : "[" Exp "]"             {% return () }
        | Dimen "[" Exp "]"     {% return () }

Exps : Exp          { % return ()}
    | Exps "," Exp  { % return ()}

Exp : true                  { % return () }
    | false                 { % return () }
    | null                  { % return () }
    | id                    { % return () }
    | int                   { % return () }
    | float                 { % return () }
    | char                  { % return () }
    | string                { % return () }
    | Exp "+" Exp           { % return ()}
    | Exp "-" Exp           { % return ()}
    | Exp "/" Exp           { % return ()}
    | Exp "^" Exp           { % return ()}
    | Exp "*" Exp           { % return ()}
    | Exp div Exp           { % return ()}
    | Exp mod Exp           { % return ()}
    | Exp ">" Exp           { % return ()}
    | Exp ">=" Exp          { % return ()}
    | Exp "<" Exp           { % return ()}
    | Exp "<=" Exp          { % return ()}
    | Exp "==" Exp          { % return ()}
    | Exp "/=" Exp          { % return ()}
    | Exp and Exp           { % return ()}
    | Exp or Exp            { % return ()}
    | "-" Exp   %prec NEG   { % return ()}
    | not Exp   %prec NEG   { % return ()}
    | "->" Exp  %prec NEG   { % return ()}
    | Accesor               {% return () }
    | CFunctions            { % return ()}
    | "(" Exp ")"           { % return ()}
    | "[" Exps "]"          { % return ()}

Assign : id "=" Exp  ";"        {% return () }
        | id "=" InstA       { % return ()}
        | Accesor "=" Exp ";"  { % return ()}

ListId : id                 {% do
                                (z, z1) <- get 
                                put ((doInsert $1 z),z1) }
        | ListId "," id     { % return ()}

Accesor : id Accs { % return ()}

Accs: Acc       { % return ()}
    | Accs Acc  { % return ()}

Acc : "." id        { % return ()}
    | "[" Exp "]"   { % return ()}

FuncCall : id "(" Fields ")" { % return ()}

Fields : {- lambda -}       { % return ()}
        | Exp               { % return ()}
        | Fields "," Exp    { % return ()}

CFunctions : inttostr "(" Exp ")"   { % return ()}
            | flotostr "(" Exp ")"  { % return ()}
            | inttoflo "(" Exp ")"  { % return ()}

Insts : Inst            { % return ()}
        | Insts Inst    { % return ()}

InstA : Assign          {% return () } 
    | Dec ";"           {% return () }
    | new ListId ";"    { % return ()}
    | read Exp ";"      { % return ()}
    | Write    		    { % return ()}
    | Return            { % return ()}
    | free Exp ";"      { % return ()}
    | FuncCall ";"      { % return ()}

Inst : InstA 	{% return () }
    | InstB 	{ % return ()}

InstB: If               { % return ()}
    | While             { % return ()}
    | Repeat            { % return ()}
    | For               { % return ()}

Return : return Exp ";"  	{ % return ()}
	|return FuncCall ";" 	{ % return ()} 

Write : write Exp ";"  { % return ()}
	| write InstA      { % return ()}

If : if "(" Exp ")" then Block                      { % return ()}
    | if "(" Exp ")" then Block else Insts end      { % return ()}

For : for "(" id Range ")" Block  { % return ()}

Range : from Exp to Exp with Exp  { % return ()}

While : while "(" Exp ")" Block  { % return ()}

Repeat : repeat Insts until Exp  { % return ()}

Block : Insts end  { % return ()}

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)


doInsert:: Lexeme Token -> Zipper -> Zipper
doInsert l z = insertS (show $ token l) (newEntry l) z

newEntry l = Entry (show $ token l) (pos l)

}