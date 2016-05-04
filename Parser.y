{

-------------- Parser para el lenguaje de programación Pandora -----------------

module Parser 
    ( parse
    ) where

import Lexer

}

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
%nonassoc "<" "<=" ">" ">=" ","
%left "==" "/="
%left     or
%left     and
%right    not
%left     "+" "-"
%left     "*" "/" mod div
%left     "^"
%right    NEG

%%

Program : Declarations Main "EOF"   { }               
	| Main "EOF" {}

Main : begin Insts end  { }

Declarations: func id "(" Param ")" ":" Type Insts end  { }
            | proc id "(" Param ")" ":" Type Insts end  { }
            | struct id has Decs end                    { }
            | union id like Decs end                    { }
            | Decs                                      { }
            | Assign                                    { }

Decs : Dec      { }
    | Decs Dec  { }

Dec : id ":" Type                   { }
    | id ":" array of Type Dimen    { }
    | new id                        { }

Param: {- lambda -}     { }
        | Params        { }

Params: Dec                 { }
        | var Dec           { }
        | Params "," Dec    { }

Type : intT     { }
    | floatT    { }
    | stringT   { }
    | charT     { }
    | boolT     { }
    | voidT     { }

Dimen : "[" Exp "]"             { }
        | Dimen "[" Exp "]"     { }

Exps : Exp          { }
    | Exp "," Exps  { }

Exp : true                  { }
    | false                 { }
    | null                  { }
    | id                    { }
    | int                   { }
    | float                 { }
    | char                  { }
    | string                { }
    | Exp "+" Exp           { }
    | Exp "-" Exp           { }
    | Exp "/" Exp           { }
    | Exp "^" Exp           { }
    | Exp "*" Exp           { }
    | Exp div Exp           { }
    | Exp mod Exp           { }
    | Exp ">" Exp           { }
    | Exp ">=" Exp          { }
    | Exp "<" Exp           { }
    | Exp "<=" Exp          { }
    | Exp "==" Exp          { }
    | Exp "/=" Exp          { }
    | Exp and Exp           { }
    | Exp or Exp            { }
    | "-" Exp   %prec NEG   { }
    | not Exp   %prec NEG   { }
    | "->" Exp  %prec NEG   { }
    | Accesor               { }
    | CFunctions            { }
    | "(" Exp ")"           { }
    | "[" Exps "]"          { }

Assign : id "=" Exp  ";"        { }
        | id "=" InstA       { }
        | Accesor "=" Exp ";"  { }

Accesor : id Accs { }

Accs: Acc       { }
    | Acc Accs  { }

Acc : "." id        { }
    | "[" Exp "]"   { }

FuncCall : id "(" Fields ")" { }

Fields : {- lambda -}       { }
        | Exp               { }
        | Exp "," Fields    { }

CFunctions : inttostr "(" Exp ")"   { }
            | flotostr "(" Exp ")"  { }
            | inttoflo "(" Exp ")"  { }

Insts : Inst            { }
        | Insts Inst    { }

InstA : Assign          { } 
    | Dec ";"           { }
    | read Exp ";"      { }
    | Write     { }
    | Return    { }
    | free Exp ";"      { }
    | FuncCall ";"      { }

Inst : InstA { }
    | InstB { }

InstB: If               { }
    | While             { }
    | Repeat            { }
    | For               { }

Return : return Exp ";"  {}
	|return InstA {}

Write : write Exp ";" {}
	| write InstA {}

If : if "(" Exp ")" then Insts end  { }
    | If else Insts end             { }

For : for "(" id Range ")" Block  { }

Range : from Exp to Exp with Exp  { }

While : while "(" Exp ")" Block  { }

Repeat : repeat Insts until Exp  { }

Block : do Insts end  { }

{

parseError :: [Lexeme Token] -> a
parseError l = case l of
  [] -> error $ "Unexpected EOF"
  _  -> error $ "Unexpected " ++ show (head l)

}
