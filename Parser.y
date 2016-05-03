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
    void        { Lexeme TokenVoid   _ }
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
    or        { Lexeme TokenOr    _ }
    and       { Lexeme TokenAnd   _ }
    "+"         { Lexeme TokenPlus  _ }
    "-"         { Lexeme TokenMinus _ }
    "*"         { Lexeme TokenAsterisk _ }
    "/"         { Lexeme TokenDivFloat _ }
    div       { Lexeme TokenDivInt _ }
    mod       { Lexeme TokenMod    _ }
    "^"         { Lexeme TokenCircum _ }

    -- unarios --
    not       { Lexeme TokenNot   _ }
    "->"        { Lexeme TokenArrow _ }

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

Program : Declarations Main "EOF"  { $1 }

Declarations: Funcs  { $1 }
            | Decs  { $1 }
            | Structs  { $1 }

Funcs : func id "(" Params ")" ":" Type Block  { $1 }
    | proc id "(" Params ")" ":" Type Block  { $1 }

Structs: struct id has Decs end  { $1 }
        | union id like Decs end  { $1 }

Decs : Dec  { $1 } 
    | Decs ";" Dec  { $1 }

Dec : id ":" Type  { $1 }
    | id ":" array of Type Dimen  { $1 }
    | new id { $1 }

Params: {- lambda -}  {  }
        | var Dec { $1 }
        | Dec  { $1 }
        | Params "," Dec  { $1 }

Block : do Insts end  { $1 }

Insts : Inst  { $1 }
        | Inst ";" Insts  { $1 }

Inst :  {- lambda -}  {  }
        | Assign ";"  { $1 }
        | Decs ";"  { $1 }
        | If  { $1 }
        | While  { $1 }
        | Repeat  { $1 }
        | For  { $1 }
        | read Exp ";"  { $1 }
        | write Exp ";"  { $1 }
        | return Exp ";"  { $1 }
        | free Exp ";" { $1 }

For : for "(" id Range ")" Block  { $1 }

Range : from Exp to Exp with Exp  { $1 }

If : if "(" Exps ")" then Insts end  { $1 }
    | If else Insts end  { $1 }

While : while "(" Exps ")" Block  { $1 }

Repeat : repeat Insts until Exp  { $1 }

Assign : id "=" Exp  { $1 }

Accesor : id Accs  { $1 }

Accs: Acc  { $1 }
    | Accs Acc  { $1 }

Acc : "." id  { $1 }
    | "[" Exp "]"  { $1 }

Type : intT  { $1 }
    | floatT  { $1 }
    | stringT  { $1 }
    | charT  { $1 }
    | boolT { $1 }

Dimen : "[" Exp "]"  { $1 }
        | Dimen "[" Exp "]"  { $1 }

Exps : Exp  { $1 }
    | Exp ";" Exps  { $1 }

Exp : true  { $1 }
    | false  { $1 }
    | null  { $1 }
    | id  { $1 }
    | int  { $1 }
    | float  { $1 }
    | char  { $1 }
    | string  { $1 }
    | void { $1 }
    | Exp "+" Exp  { $1 }
    | Exp "-" Exp  { $1 }
    | Exp "/" Exp  { $1 }
    | Exp "^" Exp  { $1 }
    | Exp "*" Exp  { $1 }
    | Exp div Exp  { $1 }
    | Exp mod Exp  { $1 }
    | Exp ">" Exp  { $1 }
    | Exp ">=" Exp  { $1 }
    | Exp "<" Exp  { $1 }
    | Exp "<=" Exp  { $1 }
    | Exp "==" Exp  { $1 }
    | Exp "/=" Exp  { $1 }
    | Exp and Exp  { $1 }
    | Exp or Exp  { $1 }
    | "-" Exp   %prec NEG  { $1 }
    | not Exp   %prec NEG  { $1 }
    | "->" Exp  %prec NEG  { $1 }
    | Accesor  { $1 }
    | CFunctions  { $1 }


CFunctions : inttostr "(" Exp ")"  { $1 }
            | flotostr "(" Exp ")"  { $1 }
            | inttoflo "(" Exp ")"  { $1 }

Main : begin Insts end  { $1 }

{

parseError _ = error "Parse error"

}


