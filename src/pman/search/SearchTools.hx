package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
import pman.search.QuickOpenItem;

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

/**
  mixin class providing methods for searching
 **/
@:expose
class SearchTools {
    /**
      * get the 'score' of the given term
      */
    public static function getScore(term:SearchTerm, sources:Array<String>, strictness:Int=0):Int {
        switch ( term ) {
            case Word( word ):
                return wfsm(sources, word);
                //return fiom(sources, word, strictness);

			default:
				return 0;
        }
    }

/* === Utility Methods === */

    /**
      * scores [t] based on the number of times it occurs in [src]
      */
    public static function wordFindScore(src:String, t:String):Int {
        var score:Int = 0,
        si:Int = 0,
        i:Int = src.indexOf(t, si);

        while (i != -1) {
            score++;
            si = (i + t.length);
            i = src.indexOf(t, si);
        }

        return score;
    }

    /**
      * (multi-)wordFindScore
      */
    public static function wfsm(src:Array<String>, t:String):Int {
        var score:Int = 0;
        for (s in src)
            score += wordFindScore(s, t);
        return score;
    }

    public static function name(q:QuickOpenItem):String {
        return switch ( q ) {
            case QOMedia( src ): src.getTitle();
            case QOPlaylist( name ): name;
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

	/**
	  * performs 'fio' search on multiple values, returning the highest returned score
	  */
	private static function fiom(srca:Array<String>, t:String, minmatched:Int=0):Int {
	    var result:Int = 0;
	    for (src in srca) {
			//result = max(result, fio(src, t, minmatched));
			result += fio(src, t, minmatched);
	    }
	    if (result < minmatched) {
	        result = 0;
	    }
	    return result;
	}
}
