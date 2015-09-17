package hxsh;

import tannus.ds.Maybe;

import hxsh.Token;
import hxsh.Expr;
import hxsh.tools.ExprTools in ETools;

using Lambda;
using hxsh.tools.ExprTools;

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

		/* 
		   continue parsing until [parseToken] returns NULL
		 */
		while (true) {
			var e = parseExpr();
			if (e == null) {
				break;
			}
			else {
				tree.push( e );
			}
		}

		return tree;
	}

	/* parse the next complete expression */
	private function parseExpr():Expr {
		var be:Null<Expr> = parseToken();
		if (be == null) {
			return EDone;
		}
		switch (be) {
			/* == Command Expression == */
			case EWord( com ):
				var args:Array<Word> = new Array();
				var redirs:Array<Redir> = new Array();

				/* == Locate All Arguments == */
				while (true) {
					var _b:Bool = false;
					var earg:Null<Expr> = parseToken();
					if (earg == null)
						break;
					
					switch (earg) {
						case EWord( w ):
							args.push(earg.word());
						
						case ERedirect( r ):
							redirs.push(earg.redir());

						default:
							args.push(earg.word());
					}
				}

				/* == Locate Any/All I/O Redirects == */
				while (true) {
					var ered:Null<Expr> = parseToken();
					if (ered == null)
						break;
					switch (ered) {
						case ERedirect(redir):
							false;
					
						default:
							redirs.push(ered.redir());
					}
				}

				/* Command Expression */
				return ECommand(com, args, redirs);

			default:
				var be:Expr = parseToken();
				if (be == null)
					return EDone;
				else
					return be;
		}
	}

	/* parse the next Token in the Stack */
	private function parseToken():Null<Expr> {
		var tk:Null<Token> = token();
		if (tk == null) {
			return null;
		}

		switch (tk) {
			/* Identifiers and single-quoted strings are interpreted literally */
			case TIdent( n ), TConst(CString(n, 1)):
				return EWord(Literal(n));

			/* function calls */
			case TIdent(fname):
				var targs = token();
				var trees:Array<Array<Token>> = new Array();
				var werds:Array<Word> = new Array();

				switch (targs) {
					case TParen(toks):
						var _buf:Array<Token> = [];
						for (t in toks) {
							if (t == TComma) {
								trees.push(_buf);
								_buf = new Array();
							} else  _buf.push( t );
						}
						if (_buf.length > 0)
							trees.push( _buf );
						werds = trees.map(Parser.parseTokenList).map(ETools.word);
						return EWord(FCall(werds.shift(), werds));
					
					default:
						tokens.unshift(targs);
				}

			/* "$" references */
			case TRefer(ref):
				switch (ref) {
					case TIdent(name):
						return EWord(Ref(RVar(name)));

					case TConst(CNumber( num )):
						var inum:Int = Math.floor(num);
						return EWord(Ref(RPos( inum )));

					case TOper('*'):
						return EWord(Ref(RAll));

					case TParen( stree ):
						save();
						tokens = stree;
						var ge:Expr = parseExpr();
						return EWord(Ref(RAll));

					default:
						throw 'Error: Cannot reference $ref';
				}

			/* === STDOUT redirection === */
			case TOper(_ => op) if (['>', '|>', '>>'].has( op )):
				if (op == '|>')
					op = '>';
				var edest:Null<Expr> = parseToken();
				if (edest == null) {
					unexpected( tk );
				}
				else {
					var mode:Int = (op == '>' ? 0 : 1);
					var w:Null<Word> = edest.word();
					if (w == null)
						unexpected( edest );
					else
						return ERedirect(ROut(w, mode));
				}

			/* === STDIN redirection === */
			case TOper('<'):
				var esrc:Maybe<Expr> = parseToken();
				var w:Null<Word> = esrc.runIf(ETools.word);
				if (w == null) {
					unexpected(tk);
				}
				else {
					return ERedirect(RIn( w ));
				}

			default:
				unexpected( tk );
		}
	}

	/* parse an expression based on the first token */
	private function parseNext(t : Token):Expr {
		switch ( t ) {
			case TConst(CBool(false)):
				return EWord(Literal('false'));

			default:
				unexpected(t);
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
		return tokens.shift();
	}

	/* get/set the current State */
	private function state(?s : PState):PState {
		if (s == null) {
			return {
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
	private inline function unexpected(thing : Dynamic):Void {
		throw 'SyntaxError: Unexpected $thing';
	}

	/* === Instance Fields === */

	private var tree : Array<Expr>;
	private var tokens : Array<Token>;
	private var states : Array<PState>;

	private static function parseTokenList(tks : Array<Token>):Expr {
		var p = new Parser();
		var elist = new Array();
		p.tokens = tks;
		while (p.tokens.length > 0) {
			var e:Expr = p.parseToken();
			if (e != null)
				elist.push( e );
			else throw 'WTFF';
		}
		return elist[0];
	}
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
