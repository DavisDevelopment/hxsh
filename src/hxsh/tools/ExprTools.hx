package hxsh.tools;

import hxsh.Expr;
import hxsh.Expr.Word;
import hxsh.Expr.Refer;
import hxsh.Expr.Redir;

/**
  * Mixin methods for working with Expressions
  */
class ExprTools {
	/**
	  * (if possible) get an expression as a Word
	  */
	public static function word(e : Expr):Null<Word> {
		switch ( e ) {
			case Expr.EWord(w):
				return w;

			default:
				return null;//throw 'TypeError: $e is not a Word';
		}
	}

	/**
	  * Check whether an expression is a Word
	  */
	public static function redir(e : Expr):Null<Redir> {
		switch ( e ) {
			case Expr.ERedirect(red):
				return red;

			default:
				return null;//throw 'TypeError: $e is not a Word';
		}
	}

	// public static function cmd(e : Expr):Null<
}
