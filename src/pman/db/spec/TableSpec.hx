package pman.db.spec;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.nore.ORegEx;

import ida.*;

import pman.async.*;

import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TableSpec {
    /* Constructor Function */
    public function new(name:String, ?indices:Array<IndexSpec>):Void {
        this.name = name;
        this.autoIncrement = false;
        this.indices = (indices != null ? indices : new Array());
    }

/* === Instance Methods === */

    public function addIndexSpec(indexSpec : IndexSpec):IndexSpec {
        indices.push( indexSpec );
        return indexSpec;
    }

    public function addIndex(name:String, ?primary:Bool, ?unique:Bool, ?nullable:Bool):IndexSpec {
        return addIndexSpec(new IndexSpec(name, unique, primary, nullable));
    }

    public function getIndex(name:String):Null<IndexSpec> {
        for (i in indices) {
            if (i.name == name) {
                return i;
            }
        }
        return null;
    }

    public function hasIndex(name : String):Bool {
        for (i in indices)
            if (i.name == name)
                return true;
        return false;
    }

    public function removeIndex(name : String):Bool {
        var i = getIndex( name );
        if (i != null) {
            indices.remove( i );
            return true;
        }
        return false;
    }

    public function getPrimaryKey():Null<String> {
        for (i in indices) {
            if ( i.primary )
                return i.name;
        }
        return null;
    }

    public function addIndices(spec : Map<String, Null<IndexAttributeSpec>>):TableSpec {
        for (name in spec.keys()) {
            var i = new IndexSpec( name ), ia = spec[name];
            if (ia != null) {
                new Object( i ).write( ia );
                addIndexSpec( i );
                trace( i );
            }
        }
        return this;
    }

/* === Computed Instance Fields === */

    public var primaryKey(get, never):String;
    private inline function get_primaryKey():String return getPrimaryKey();

/* === Instance Fields === */

    public var name : String;
    public var autoIncrement : Bool;
    public var indices : Array<IndexSpec>;
}

typedef IndexAttributeSpec = {
    ?primary: Bool,
    ?unique: Bool,
    ?nullable: Bool
};
