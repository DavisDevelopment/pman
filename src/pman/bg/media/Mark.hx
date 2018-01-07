package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.db.*;
import pman.bg.tasks.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;

import haxe.Serializer;
import haxe.Unserializer;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;
using tannus.async.Asyncs;

class Mark {
    /* Constructor Function */
    public function new(type:MarkType, time:Float) {
        this.type = type;
        this.time = time;
    }

/* === Instance Methods === */

    public function clone():Mark {
        return new Mark(type, time);
    }

    public function toJson():JsonMark {
        return {
            time: time,
            type: markTypeToJson( type )
        };
    }

    /**
      * serialize [this] Mark
      */
    @:keep
    public function hxSerialize(s : Serializer):Void {
        inline function w(x:Dynamic) s.serialize( x );

        w( type );
        w( time );
    }

    /**
      * deserialize [this] Mark
      */
    @:keep
    public function hxUnserialize(u : Unserializer):Void {
        inline function v<T>():T return u.unserialize();

        type = v();
        time = v();
    }

/* === Instance Fields === */

    public var type(default, null): MarkType;
    public var time(default, null): Float;

    private var _wl:Null<Array<String>> = null;

/* === Static Methods === */

    public static function markTypeToJson(type: MarkType):Dynamic {
        var o:Object = {};
        switch ( type ) {
            case Begin:
                o.set('tn', 'begin');

            case End:
                o.set('tn', 'end');

            case LastTime:
                o.set('tn', 'last');

            case Named(name):
                o.set('tn', 'named');
                o.set('n', name);

            case Scene(stype, name):
                o.set('tn', 'scene');
                o.set('st', (switch ( stype ) {
                    case SceneBegin: 'begin';
                    case SceneEnd: 'end';
                }));
                o.set('n', name);
        }
        return o;
    }

    public static function jsonToMarkType(o: Dynamic):Null<MarkType> {
        var o:Object = o;
        inline function has(n:String):Bool return o.exists( n );
        inline function get<T>(n: String):Null<T> return o.get( n );

        if (Reflect.isObject( o )) {
            var jsonType:JsonMarkType = o;
            switch ( jsonType ) {
                case {tn: id, n: null, st: null}:
                    switch (id.toLowerCase()) {
                        case 'begin':
                            return MarkType.Begin;
                        case 'end':
                            return MarkType.End;
                        case 'last':
                            return MarkType.LastTime;
                        case other:
                            throw 'Error: Invalid MarkType-name "$other"';
                    }

                case {tn:'named', n:name, st:null}:
                    return MarkType.Named( name );

                case {tn:'scene', n:name, st:id}:
                    return MarkType.Scene((switch (id.toLowerCase()) {
                        case 'begin': SceneBegin;
                        case 'end': SceneEnd;
                        case other: throw 'Error: Invalid SceneMarkType-name "$other"';
                    }), name);
            }
        }
        else {
            return null;
        }
    }

    public static function fromJsonMark(jsonMark: JsonMark):Mark {
        return new Mark(jsonToMarkType( jsonMark.type ), jsonMark.time);
    }
}

enum MarkType {
    Begin;
    End;
    LastTime;

    Named(name: String);
    Scene(type:SceneMarkType, name:String);
}

enum SceneMarkType {
    SceneBegin;
    SceneEnd;
}

typedef JsonMark = {
    time: Float,
    type: JsonMarkType
};

typedef JsonMarkType = {
    tn: String,
    ?st: Int,
    ?n: String
};
