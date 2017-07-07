package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import gryffin.display.*;

import haxe.extern.EitherType;

import pman.Globals.*;
import tannus.math.TMath.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

@:expose('Snapshots')
class Snapshots {
    /* Constructor Function */
    public function new(?root : Path):Void {
        this.root = (root != null ? root : preferences.snapshotPath);
    }

/* === Instance Methods === */

    /**
      * get all item names as Strings
      */
    public function allNames():Array<String> {
        return Fs.readDirectory( root );
    }

    /**
      * get Paths to all items
      */
    public function allPaths():Array<Path> {
        return allNames().map.fn(sub( _ ));
    }

    /**
      * get all items
      */
    public function all():Array<Snapshot> {
        return allNames().map.fn(new Snapshot(sub(_)));
    }

    /**
      * filter by String
      */
    public function stringFilter(f : String->Bool):Array<String> {
        var res = [];
        for (n in allNames()) {
            if (f( n )) {
                res.push( n );
            }
        }
        return res;
    }

    /**
      * mapped filter by String
      */
    public function mappedStringFilter<T>(test:T->Bool, transform:String->T):Array<T> {
        var res:Array<T> = new Array();
        for (name in allNames()) {
            var value = transform( name );
            if (test( value )) {
                res.push( value );
            }
        }
        return res;
    }

    /**
      * filter by Path
      */
    public function pathFilter(f : Path->Bool):Array<Path> {
        return mappedStringFilter(f, fn(new Path( _ )));
    }

    /**
      * filter by SnapName
      */
    public function nameFilter(f : SnapName->Bool):Array<SnapName> {
        return mappedStringFilter(f, fn(new SnapName( _ )));
    }

    /**
      * return the first string for which [f] return true
      */
    public function stringFind(f : String->Bool):Maybe<String> {
        for (name in allNames()) {
            if (f( name )) {
                return name;
            }
        }
        return null;
    }

    /**
      * return the first SnapName for which [f] returns true
      */
    public function nameFind(f : SnapName->Bool):Maybe<SnapName> {
        return stringFind(function(s) {
            return f(new SnapName( s ));
        }).ternary(new SnapName(_), null);
    }

    /**
      * return the first Path for which [f] returns true
      */
    public function pathFind(f : Path->Bool):Maybe<Path> {
        return stringFind(function(s : String):Bool {
            return f(sub( s ));
        }).ternary(sub(_), null);
    }

    /**
      * get items by title, time, or both
      */
    public function search_name(?title:GSTitle, ?time:GSTime):Array<SnapName> {
        var gs = _search(title, time);
        return nameFilter(function(name) {
            return gs.test( name );
        });
    }

    /**
      * get items by title, time, or both
      */
    public function search_string(?title:GSTitle, ?time:GSTime):Array<String> {
        return search_name(title, time).map.fn(_.toString());
    }

    /**
      * get items by title, time, or both
      */
    public function search_path(?title:GSTitle, ?time:GSTime):Array<Path> {
        return search_name(title, time).map.fn(sub(_.toString()));
    }

    /**
      * get items by title, time, or both
      */
    public function search(?title:GSTitle, ?time:GSTime):Array<Snapshot> {
        return search_name(title, time).map.fn(new Snapshot(sub(_.toString())));
    }

    /**
      * search item by title, time, or both
      */
    public function get_name(?title:GSTitle, ?time:GSTime):Maybe<SnapName> {
        var search = _search(title, time);
        return nameFind(function(name) {
            return search.test( name );
        });
    }

    /**
      * search item by title, time, or both
      */
    public function get_string(?title:GSTitle, ?time:GSTime):Maybe<String> {
        return get_name(title, time).ternary(_.toString(), null);
    }

    /**
      * search item by title, time, or both
      */
    public function get_path(?title:GSTitle, ?time:GSTime):Maybe<Path> {
        return get_string(title, time).ternary(sub(_), null);
    }

    /**
      * search item by title, time, or both
      */
    public function get(?title:GSTitle, ?time:GSTime):Maybe<Snapshot> {
        return get_path(title, time).ternary(new Snapshot(_), null);
    }

    /**
      * create and return a subpath of [root]
      */
    public function sub(s : String):Path {
        return root.plusString( s );
    }

    /**
      * create and return a new GetSearch
      */
    public function _search(?title:GSTitle, ?time:GSTime):GetSearch {
        return new GetSearch(
            (if (title != null) (if (!Reflect.isFunction( title )) fn(x=>x==title) else title) else null),
            (if (time != null) (if (!Reflect.isFunction( time )) fn(x=>x==time) else time) else null)
        );
    }

/* === Instance Fields === */

    public var root(default, null):Path;
}

class GetSearch {
    /* Constructor Function */
    public inline function new(?title:String->Bool, ?time:Float->Bool):Void {
        this.title = title;
        this.time = time;
    }

    /**
      * check that the given SnapName matches the criteria specified by [this]
      */
    public function test(name : SnapName):Bool {
        return (
            (if (title != null) title( name.title ) else true) &&
            (if (time != null) time( name.time ) else true)
        );
    }

    public var title : Null<String -> Bool>;
    public var time  : Null<Float -> Bool>;

    public static inline function equals(?title:String, ?time:Float):GetSearch {
        return new GetSearch(
            (title != null ? fn(x=>x==title) : null),
            (time != null ? fn(x=>x==time) : null)
        );
    }
}

class SnapName {
    public function new(name : String):Void {
        name = name.beforeLast('.png');
        title = name.beforeLast('@');
        time = Std.parseFloat(name.afterLast('@'));
    }

    public function toString():String {
        return '$title@$time.png';
    }

    public var title : String;
    public var time : Float;
}

typedef GSTitle = EitherType<String, String -> Bool>;
typedef GSTime = EitherType<Float, Float -> Bool>;
