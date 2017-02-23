package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;

import haxe.Serializer;
import haxe.Unserializer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class SearchEngine<T> {
	/* Constructor Function */
	public function new():Void {
		caseSensitive = false;
		useEReg = false;
		useGlobStar = false;

		context = new Array();
		terms = new Array();
	}

/* === Instance Methods === */

	/**
	  * set the search term String
	  */
	public function setSearch(s : String):Void {
		terms = new Array();
		parseStringToTerms( s );
		trace( terms );
	}

	/**
	  * set the Context
	  */
	public function setContext(a : Array<T>):Void {
		context = a;
	}

	/**
	  * perform the search
	  */
	public function getMatches():Array<Match<T>> {
		if ( !caseSensitive ) {
			terms = terms.map.fn(_.toLowerCase());
		}

		var matches:Array<Match<T>> = new Array();
		for (item in context) {
			var m = _match( item );
			if (m != null) {
				matches.push( m );
			}
		}

		return matches;
	}

	/**
	  * attempt a Match
	  */
	private function _match(item : T):Null<Match<T>> {
		var text = getValue( item );
		if ( !caseSensitive ) text = text.toLowerCase();
		trace('indexing $text');
		var score:Int = 0;
		var minScore = 2;
		for (term in terms) {
			var fion = fio(text, term);
			if (fion > 0) {
				if (term.length >= minScore && fion < minScore) {
					continue;
				}
				else {
					score += fion;
				}
			}
		}
		if (score > 0) {
			return {
				item: item,
				score: score
			};
		}
		else {
			return null;
		}
	}

	/**
	  * get the String value of the given context item
	  */
	private function getValue(item : T):String {
		return '';
	}

	/**
	  * split an input String into terms,
	  * performing some rudimentary parsing along the way
	  */
	private function parseStringToTerms(input : String):Void {
		input = __checkFirstChar(input.trim());
		
		var currentWord:String = '';
		var lastWasBreaker:Bool = true;
		var index:Int = 0;
		inline function flush(){
			if (currentWord.length > 0) {
				terms.push( currentWord );
				currentWord = '';
			}
		}

		while (index < input.length) {
			var c:Byte = input.byteAt( index );
			if (c.isAlphaNumeric() || ACCEPTIBLE_SYMBOLS.has( c )) {
				currentWord += c;
			}
			else if (c.isWhiteSpace()) {
				if ( !lastWasBreaker ) {
					flush();
					lastWasBreaker = true;
				}
			}
			index++;
		}
		flush();
	}

	/**
	  * interprets the search-term leader, if there is any
	  * returns the input String stripped the leader
	  */
	private function __checkFirstChar(i : String):String {
		switch (i.charAt( 0 )) {
			// regular expression search
			case '~':
				useEReg = true;
				return i.slice( 1 );

			default:
				return i;
		}
	}

	/**
	  * searches for [t] in [src], finding the index in [src] at which [t] begins,
	  * but instead of looking for an exact match, it just counts how many characters of [t]
	  * appear in [src] in order, and returns that value as well
	  */
	private static function fio(src:String, t:String, minmatched:Int=0):Int {
		//var start:Int = 0;
		var mostmatched:Int = 0;
		var nmatched:Int = 0;
		// reset; keep largest
		inline function rkl(){
			mostmatched = Std.int(Math.max(nmatched, mostmatched));
			nmatched = 0;
		}
		for (i in 0...src.length) {
			var c = src.charAt( i );
			if (c == t.charAt( nmatched  )) {
				nmatched++;
			}
			else if (nmatched > 0) {
				rkl();
			}
			else {
				continue;
			}
		}
		rkl();
		if (mostmatched > 0) {
			return mostmatched;
		}
		else {
			return 0;
		}
	}

/* === Instance Fields === */

	public var context : Array<T>;
	public var terms : Array<String>;

	public var caseSensitive : Bool;
	public var useEReg : Bool;
	public var useGlobStar : Bool;

/* === Static Fields === */

	private static inline var ACCEPTIBLE_SYMBOLS:String = '#,./-';
}

typedef Match<T> = {
	item : T,
	score : Int
	//positions : Array<Int>
};
