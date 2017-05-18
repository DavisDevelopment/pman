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

class DatabaseSpec {
    /* Constructor Function */
    public function new(name:String, version:Int=1):Void {
        this.name = name;
        this.version = version;
        this.tables = new Array();
    }

/* === Instance Methods === */

    public function getTable(name : String):Null<TableSpec> {
        return tables.firstMatch.fn(_.name == name);
    }
    public function hasTable(name:String):Bool {
        return (getTable( name ) != null);
    }
    public function addTableSpec(table : TableSpec):TableSpec {
        tables.push( table );
        return table;
    }
    public function addTable(name:String, ?indices:Array<IndexSpec>):TableSpec {
        return addTableSpec(new TableSpec(name, indices));
    }
    public function removeTable(name:String):Bool {
        var t = getTable( name );
        if (t == null) 
            return false;
        tables.remove( t );
        return true;
    }
    public function open(done : Cb<Database>):Void {
        var builder = new DatabaseSpecBuilder( this );
        builder.open( done );
    }

/* === Instance Fields === */

    public var name : String;
    public var version : Int;
    public var tables : Array<TableSpec>;
}
