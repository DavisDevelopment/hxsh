package hxsh;

import hxsh.Token;
import hxsh.Expr;

class Parser {
    /* Constructor Function */
    public function new():Void {
        
        reset();
    }
    
/* === Instance Methods === */

    /* parse out a Token tree, and return the result */
    public function parse(tks : Array<Token>):Array<Expr> {
        reset();
        tokens = tks;
        
        while (true) {
            var e = parseToken();
            if (e == null) {
                break;
            }
            else {
                tree.push( e );
            }
        }
        
        return tree;
    }

    /* parse the next Token in the Stack */
    private function parseToken():Null<Expr> {
        var tk:Null<Token> = token();
        if (tk == null) {
            return null;
        }
        
        switch (tk) {
            case TIdent( n ):
                var cmd = parseNext(n);
                return cmd;
                
            default:
                unexpected( tk );
        }
    }
    
    /* parse an expression based on the first token */
    private function parseNext(t : Token):Expr {
        switch (t) {
            case TIdent(name):
                var args:Array<
        }
    }

    /* Restore [this] Parser to it's default state */
    private function reset():Void {
        tree = new Array();
        tokens = new Array();
        states = new Array();
    }
    
    /* get the next Token in the Stack */
    private function token():Null<Token> {
        return tokens.unshift();
    }
    
    /* get/set the current State */
    private function state(?s : PState):PState {
        var r:PState;
        if (s == null) {
            r = {
                'tokens': tokens.copy(),
                'tree': tree.copy()
            };
        }
        else {
            tree = s.tree;
            tokens = s.tokens;
            return s;
        }
    }
    
    /* add the current State to the stack */
    private function save():Void {
        states.push(state());
    }
    
    /* restore the most recent state in the stack */
    private function restore():Void {
        var s:Null<PState> = states.pop();
        if (s != null) {
            state( s );
        }
        else {
            throw 'Error: no State to restore from!';
        }
    }
    
    /* throw an 'unexpected' Error */
    private inline function unexpected(tk : Token):Void {
        throw 'SyntaxError: Unexpected $tk';
    }
    
/* === Instance Fields === */

    private var tree : Array<Expr>;
    private var tokens : Array<Token>;
    private var states : Array<PState>;
}

/* Parser State */
private typedef PState = {
    tokens : Array<Token>,
    tree : Array<Expr>
};

/* Errors thrown by Parser */
enum Errs {
    /* Token stack is empty */
    EmptyStack;
}