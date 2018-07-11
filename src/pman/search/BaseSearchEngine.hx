package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.dict.DictKey;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;
//import pman.search.SearchTerm;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.ds.AnonTools;
using tannus.ds.DictTools;
using tannus.ds.MapTools;
using tannus.ds.SortingTools;
using tannus.FunctionTools;
using pman.media.MediaTools;
using pman.search.SearchTools;

/**
  engine used to index a list of values based on some arbitrary 'term'
 **/
class BaseSearchEngine<Item, Term:DictKey> {
    /* Constructor Function */
    public function new() {
        //initialize variables
    }

/* === Instance Methods === */
/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var memory: BaseSearchEngineMemory<Item, Term>;
}

class BaseSearchEngineMemory<Item, Term:DictKey> {
    /* Constructor Function */
    public function new(engine:BaseSearchEngine<Item, Term>):Void {
        this.engine = engine;
        this.uids = new Dict();
        this.indices = new Dict();
    }

/* === Instance Fields === */

    public var engine(default, null): BaseSearchEngine<Item, Term>;
    public var uids: Dict<String, Item>;
    public var indices: Dict<Term, BaseSearchEngineMemoryNode<Item>>;
}

/**
  purpose of class
 **/
class BaseSearchEngineMemoryNode<T> implements tannus.ds.IComparable<BaseSearchEngineMemoryNode<T>> {
    /* Constructor Function */
    public function new(mem:BaseSearchEngineMemory<T, Dynamic>, uid:String, item:T, score:Int=0) {
        this.mem = mem;
        this.uid = uid;
        this.item = item;
        this.score = score;
    }

/* === Instance Methods === */

    public inline function clone():BaseSearchEngineMemoryNode<T> {
        return new BaseSearchEngineMemoryNode(mem, uid, item, score);
    }

    public inline function incrementScore(n: Int = 1):Int {
        return (score += n);
    }

    public function compareTo(node: BaseSearchEngineMemoryNode<T>):Int {
        return Reflect.compare(uid, node.uid);
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    public var mem(default, null): BaseSearchEngineMemory<T, Dynamic>;

    public var uid(default, null): String;
    public var item(default, null): T;
    public var score(default, default): Int;
}
