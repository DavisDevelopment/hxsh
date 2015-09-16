package hxsh;

enum Expr {
    ECommand(name:String, args:Array<Value>);
    // EAnd(left:Expr, right:Expr);
}

enum Value {
    VNull;
    VBool(v : Bool);
    VNumber(n : Float);
    VString(s : String);
}