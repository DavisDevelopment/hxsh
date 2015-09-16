package hxsh;

import tannus.io.ByteArray;
import tannus.io.Byte;

import hxsh.Token in Expr;

using StringTools;
using Lambda;

class Lexer {
	/* Constructor Function */
	public function new():Void {

		reset();
	}

	/* === Instance Methods === */

	/**
	 * Parse some String input
	 */
	public function lexString(s : String):Array<Expr> {
		reset();
		buffer = ByteArray.fromString(s + ' ');
		trace(buffer.toArray());

		while ( true ) {
			var e:Null<Expr> = parseNext();
			if (e == null)
				break;
			else {
				tree.push( e );
			}
		}

		return tree;
	}

	/**
	 * Parse the next expression
	 */
	private function parseNext():Null<Expr> {
		var c:Byte = current();

		/* End of Input */
		if (atend()) {
			return null;
		}

		/* Whitespace */
		else if (c.isWhiteSpace()) {
			if (c.isLineBreaking())
				line++;
			advance();
			return parseNext();
		}

		/* === Numeric Literals === */
		else if (c.isNumeric()) {
			var snum:String = (c.aschar + '');
			advance();
			c = current();
			while (!atend() && (c.isNumeric() || c == ".".code)) {
				snum += (c.aschar);
				c = advance();
			}
			return TConst(CNumber(Std.parseFloat(snum)));
		}

		/* === Identifiers === */
		else if (c.isLetter()) {
			var id:String = (c.aschar + '');
			advance();
			c = current();
			while (!atend() && isIdentChar( c )) {
				id += c;
				c = advance();
			}
			// id += c;
			switch ( id ) {
				/* Boolean Identifiers */
				case 'true', 'false':
					return TConst(CBool(id == 'true'));

				/* Null */
				case 'null':
					return TConst(CNull);

				/* Any Other Identifier */
				default:
					var tok:Token = TIdent( id );
					var _pos:Int = cursor;
					
					/* Attempt to get the next token in the tree */
					var nxt:Null<Token> = parseNext();
					
					/* if there is no next token */
					if (nxt == null) {
						//- just return [tok]
						return tok;
					}

					/* otherwise */
					else {
						/* determine what to do with it */
						switch (nxt) {
							/* in the case of a tuple */
							case TTupleDef(vals):
								return TFCall(id, vals);

							/* anything else */
							default:
								cursor = _pos;
								return tok;
						}
					}
			}
		}

		/* === Strings === */
		else if (c == '"' || c == "'") {
			var del:Byte = c;
			var str:String = '';
			advance();
			c = current();
			while (!atend() && c != del) {
				str += c;
				c = advance();
			}
			advance();
			return TConst(CString(str, (del=='"'.code?2:1)));
		}

		/* === Operators === */
		else if (isOperator( c )) {
			var op:String = (c + '');
			advance();
			c = current();
			while (!atend() && isOperator(c)) {
				op += c;
				c = advance();
			}
			return TOper(op);
			/*
			var _c:Int = cursor;
			var nxt:Null<Expr> = parseNext();
			if (nxt == null)
				throw 'SyntaxError: unexpected end of input';
			var up:Token = TUnop(op, nxt);
			switch ( up ) {
				case TUnop("$", TIdent(name)):
					return TVar(name);

				case TUnop("$", TParen(ctoks)):
					return TSubstitute( ctoks );

				case TUnop("&", e):
					return TRef( e );

				case TUnop("*", e):
					return TDeref( e );

				default:
					cursor = _c;
					return up;
			}
			*/
		}

		/* === Comma (Placeholder Token) === */
		else if (c == ','.code) {
			advance();
			return TComma;
		}

		/* === Groups and Tuples === */
		else if (c == '('.code) {
			advance();
			c = current();
			var sgroup:String = '';
			var lvl:Int = 1;
			
			while (!atend() && lvl > 0) {
				if (c == '('.code)
					lvl++;
				
				else if (c == ')'.code)
					lvl--;

				if (lvl > 0) {
					sgroup += c;
					c = advance();
				}
			}
			sgroup += c;
			advance();
			
			/* == Parse the Group == */
			var grup:Array<Token> = (new Lexer().lexString(sgroup));
			
			/* if it has top-level commas, then it's a tuple */
			if (grup.has(TComma)) {
				var tupdef:Array<Token> = new Array();
				var i:Int = 0;
				var expecting:Bool = true;

				while (true) {
					var tok:Token = grup[i++];
					if (tok == null) {
						break;
					} 
					else {
						switch (tok) {
							case TComma:
								if (!expecting) {
									expecting = true;
									continue;
								} 
								else 
									throw 'SyntaxError: Unexpected ","';

							default:
								if (expecting) {
									tupdef.push( tok );
									expecting = false;
									continue;
								}
								else
									throw 'SyntaxError: Unexpected "$tok"';
						}
					}
				}
				
				/* Ensure that the last Token is not a comma */
				if (expecting) {
					throw 'SyntaxError: Unexpected ")"';
				}

				/* Create and return the Tuple */
				return TTupleDef( tupdef );
			}
			else {
				/* Create and return the grouped Tokens */
				return TParen( grup );
			}
		}

		/* === Blocks and Expansions === */
		// else if (

		/* Anything Else */
		else {
			throw 'Unexpected "$c" on line ${line + 1}';
		}
	}

	/**
	  * Generic Function for handling grouping symbols
	  */
	private function consumeGroup(opener:Byte, closer:Byte, ?escaper:Byte):String {
		var lvl:Int = 1;
		var snippt:String = '';
		var c:Byte = advance();
		while (!atend() && lvl > 0) {
			/* Nested Group */
			if (c == opener) {
				lvl++;
			}

			/* End of Group */
			else if (c == closer) {
				lvl--;
			}

			if (lvl > 0) {
				snippt += c;
			}
			c = advance();
		}
		return snippt;
	}

	/**
	  * Check whether [c] is a pash identifier character
	  */
	private function isIdentChar(c : Byte):Bool {
		return (c.isAlphaNumeric() || [
			'.'.code
		].has( c ));
	}

	/**
	  * Check whether [c] is a control-character
	  */
	private function isControlChar(c : Byte):Bool {
		var ctrlChars = ['&'.code, '|'.code, ';'.code, '('.code, ')'.code];
		return (ctrlChars.has(c.asint));
	}

	/**
	  * Check whether [c] is an operator
	  */
	private function isOperator(c : Byte):Bool {
		var opChars:Array<String> = [
			'+', '-', '~',
			'$', '&', '*',
			'>', '<', '?'
		];
		return (opChars.has(c.aschar));
	}

	/**
	 * Restore [this] Parser to it's default state
	 */
	private inline function reset():Void {
		buffer = new ByteArray();
		tree = new Array();
		cursor = 0;
	}

	/**
	 * Check whether we have reached the end of our input
	 */
	private function atend():Bool {
		return (cursor >= (buffer.length - 1));
	}

	/**
	 * Get the current Byte
	 */
	private function current():Byte {
		return buffer.get( cursor );
	}

	/**
	 * Get the next Byte
	 */
	private function next(?d:Int = 1):Byte {
		return buffer.get(cursor + d);
	}

	/**
	 * Advance to the next Byte
	 */
	private function advance(d:Int = 1):Byte {
		cursor += d;
		return current();
	}

	/* === Instance Fields === */

	private var buffer : ByteArray;
	private var cursor : Int;
	private var line : Int;

	private var tree : Array<Expr>;
}