package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.search.SearchTerm;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.TMath;
using pman.search.SearchTools;

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
		var values = getValues( item );
		if ( !caseSensitive ) {
		    values = values.map.fn(_.toLowerCase());
        }
		var score:Int = 0;
		var minScore = 2;
		for (term in terms) {
		    var fion = term.getScore( values );
		    score += fion;
		}
		if (score > minScore) {
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
	  * get multiple values for the given context item
	  */
	private function getValues(item : T):Array<String> {
	    return [''];
	}

	/**
	  * split an input String into terms,
	  * performing some rudimentary parsing along the way
	  */
	private function parseStringToTerms(input : String):Void {
	    input = __checkFirstChar(input.trim());
	    terms = SearchTermParser.runString( input );
	    trace(terms + '');
	}
	/*
	private function parseStringToTerms_(input : String):Void {
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
	*/

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

/* === Instance Fields === */

	public var context : Array<T>;
	public var terms : Array<SearchTerm>;

	public var caseSensitive : Bool;
	public var useEReg : Bool;
	public var useGlobStar : Bool;

/* === Static Fields === */

}
