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

/**
  engine for indexing a list of values based on a search term
 **/
class SearchEngine<T> {
	/* Constructor Function */
	public function new():Void {
		caseSensitive = false;
		strictness = 3;

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
		var minScore = strictness;
		for (term in terms) {
		    var fion = term.getScore(values, strictness);
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
	}

	/**
	  * interprets the search-term leader, if there is any
	  * returns the input String stripped the leader
	  */
	private function __checkFirstChar(i : String):String {
	    return i;
	}

/* === Instance Fields === */

	public var context : Array<T>;
	public var terms : Array<SearchTerm>;

	public var caseSensitive : Bool;
	public var strictness : Int;

/* === Static Fields === */

}
