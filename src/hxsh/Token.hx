package hxsh;

enum Token {
    /* Constant Expression */
    TConst(c : Const);
    
    /* Identifier */
    TIdent(id : String);

    /* Unary Operators */
    TOper(op : String);

    /* Group */
    TParen(tree : Array<Token>);

    /* Tuple */
    TTupleDef(values : Array<Token>);

    /* Function Invokation */
    TFCall(name:String, args:Array<Token>);

    /* Variable Reference */
    // TVar(name : String);

    /* Reference Creation */
    // TRef(expr : Token);
    
    /* Dereferencing */
    // TDeref(expr : Token);

    /* Substitution */
    // TSubstitute(toks : Array<Token>);

    TComma;
}

enum Const {
    CNumber(n : Float);
    CString(s:String, t:Int);
    CBool(b : Bool);
    CNull;
}
