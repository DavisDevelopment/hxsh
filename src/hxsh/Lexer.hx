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
			if (c.isLineBreaking()) {
				line++;
				if (tree[tree.length-1] != TLineBreak)
					return TLineBreak;
			}
			advance();
			return parseNext();
		}

		/* === Numeric Literals === */
		else if (c.isNumeric()) {
			var snum:String = (c.aschar);
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
				var escaping:Bool = (c == '\\'.code);
				c = advance();
				if (escaping) {
					id += c;
					c = advance();
				}
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

		/* === References === */
		else if (c == "$".code) {
			advance();
			var _i:Int = cursor;
			var nxt = parseNext();
			if (nxt == null)
				throw "Unexpected '$' on line "+line;

			switch (nxt) {
				case TConst(_), TIdent(_), TParen(_):
					return TRefer(nxt);

				default:
					cursor = _i;
					return TOper("$");
			}
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
			
			/* if [op] is a control symbol */
			if (isControl( op )) {
				return TCtrl(op);
			}
			
			/* other symbols */
			else {
				return TOper(op);
			}
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
			// sgroup += c;
			advance();
			
			/* == Parse the Group == */
			var grup:Array<Token> = (new Lexer().lexString(sgroup));
			return TParen( grup );
			/* if it has top-level commas, then it's a tuple */
			/*
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
				if (expecting) {
					throw 'SyntaxError: Unexpected ")"';
				}
				return TTupleDef( tupdef );
			}
			else {
				return TParen( grup );
			}
			*/
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
		return (!(isControl(c.aschar) || c.isWhiteSpace()));
	}

	/**
	  * Check whether [c] is a control-character
	  */
	private function isControl(c : String):Bool {
		return ([
			';', '&', '&&', '||'
		].has( c ));
	}

	/**
	  * Check whether [c] is an operator
	  */
	private function isOperator(c : Byte):Bool {
		var opChars:Array<String> = [
			'~',
			'$', '&', '*',
			'>', '<', '?',
			';', '|'
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
		line = 0;
	}

	/**
	 * Check whether we have reached the end of our input
	 */
	private function atend():Bool {
		return (cursor >= (buffer.length - 1) || buffer[cursor] == 0);
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
