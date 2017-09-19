package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.async.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;

import pman.Paths;
import pman.ds.OnceSignal as ReadySignal;
import pman.Globals.*;

import nedb.DataStore;

import Slambda.fn;
import tannus.math.TMath.*;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PManDatabase {
    /* Constructor Function */
    public function new():Void {
        path = (Paths.userData().plusString('pmdb'));
        ops = new Operators();

        rs = new ReadySignal();
    }

/* === Instance Methods === */

    public function init(?done : VoidCb):Void {
        if (!Fs.exists( path )) {
            Fs.createDirectory( path );
        }

        var mds = new DataStore({
            filename: dsfilename('media.db')
        });
        mds.loadDatabase(function(?error) {
            if (error != null) {
                throw error;
            }
            else {
                testDatastore( mds );
            }
        });
    }

    private function testDatastore(store : DataStore):Void {
        var win = tannus.html.Win.current;
        
        var ms = wrap('media.db', MediaStore);
        ms.init(function(?error) {
            if (error != null) {
                report( error );
            }
            else {
                var doc:Dynamic = {
                    uri: 'file:///home/ryan/Videos/Popcorn/porn/09-12-2017/Marley Brinx/Marley Brinx -- Tight Teen Yoga Pants Fuck --  720p.mp4',
                    data: {
                        views: 2,
                        rating: null,
                        description: null,
                        starred: false,
                        marks: [],
                        tags: ['tight', 'teen', 'yoga'],
                        actors: [],
                        meta: {
                            duration: 696969.0,
                            video: {width: 1000, height: 1000, frame_rate: '', time_base: ''},
                            audio: {}
                        }
                    }
                };
                ms._mutate(function(q:Query) {
                    return q.has('tags', ['teen', 'tiny']);
                },
                function(m:Modification) {
                    m.increment({'data.views': 1});
                    m.addToSet({'data.tags': 'hd'});
                    m.set({'data.starred': true});
                },
                function(?error, ?row) {
                    trace( error );
                    trace( row );
                });
            }
        });
    }

    /**
      * create a TableWrapper
      */
    private function wrap<T:TableWrapper>(name:String, ?type:Class<T>):T {
        if (type == null) {
            type = untyped TableWrapper;
        }
        var store:DataStore = new DataStore({
            filename: dsfilename( name )
        });
        return Type.createInstance(type, untyped [this, store]);
    }

    public inline function onready(action : Void->Void):Void rs.await( action );
    public inline function dsfilename(name : String):String {
        return Std.string(path.plusString(name).normalize());
    }

/* === Instance Fields === */

    public var path: Path;
    public var ops : Operators;
    
    private var rs : ReadySignal;
}
