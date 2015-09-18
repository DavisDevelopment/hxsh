package hxsh;

enum Expr {
/* === Atomic Expressions === */
	
	/* Word Expression */
	EWord(w : Word);

	/* Redirection */
	ERedirect(redir : Redir);

	/* [END OF FILE] */
	EDone;

	/* Grouped set of expressions */
	EGrouped(stree : Array<Expr>);

/* === Compound Expressions === */
	
	ECommand(cmd:Word, args:Array<Word>, redirs:Array<Redir>);
}

enum Value {
    VNull;
    VBool(v : Bool);
    VNumber(n : Float);
    VString(s : String);
}

enum Word {
	/* Standard Word */
	Literal(s : String);
	
	/* Single and Double Quoted Strings */
	SingleQuote(s : String);
	DoubleQuote(e : Expr);
	FCall(f:Word, args:Array<Word>);

	/* Reference to the output of [cmd] Expression */
	OutputOf(cmd : Expr);

	/* Reference to a variable */
	Ref(ref : Refer);
}

enum Refer {
	/* Named Variable */
	RVar(name : String);

	/* Positional Variable */
	RPos(pos : Int);

	/* all positional vars */
	RAll;

	/* number of positional vars */
	RCount;
}

/* redirection expressions */
enum Redir {
	/* stdout */
	ROut(dest:Word, mode:Int);
	
	/* stderr */
	RErr(dest:Word, mode:Int);

	/* stdin */
	RIn(src : Word);
}
