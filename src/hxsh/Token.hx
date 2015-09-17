package hxsh;

enum Token {
    /* Constant Expression */
    TConst(c : Const);
    
    /* Identifier */
    TIdent(id : String);

    /* Operators */
    TOper(op : String);

    /* Control Operators */
    TCtrl(op : String);
    
    /* Group */
    TParen(tree : Array<Token>);

    /* The "$" symbol preceding something */
    TRefer(tk : Token);

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
    TLineBreak;
}

enum Const {
    CNumber(n : Float);
    CString(s:String, t:Int);
    CBool(b : Bool);
    CNull;
}
