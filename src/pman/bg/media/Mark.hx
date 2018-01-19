package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.math.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.db.*;
import pman.bg.tasks.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;
import pman.tools.SimpleWordLexer;

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
        u.setResolver(new MediaData.PatchTypeResolver());
        inline function v<T>():T return u.unserialize();

        type = v();
        time = v();
    }

    public function getName():Null<String> {
        switch ( type ) {
            case Named(name):
                return name;

            case Scene(_, name):
                return name;

            default:
                return null;
        }
    }

    public function hasName():Bool {
        return type.match(Named(_)|Scene(_, _));
    }

    public function format(all: Array<Mark>):Null<String> {
        var text = getName();
        if (!text.hasContent())
            return null;
        
        var i:Int = all.indexOf( this );
        inline function set(x:String, y:Dynamic) {
            text = text
                .replace('%$x', Std.string( y ))
                .replace('@$x', Std.string( y ));
        }

        set('i', i);
        var fw = firstWord();
        if (fw.hasContent()) {
            var mutateWord:String->String = (x -> x.toLowerCase());
            var nfw = nfirstWords(all, mutateWord);
            var wi = markNthWordIndexOf(all, this, 0, mutateWord);

            set('w', (wi > 1 ? '$wi' : ''));
            set('W', (wi + 1));
        }
        set('t', Time.fromFloat( time ));
        return text;
    }

    /**
      * parse out [this] Mark's "word-list"
      */
    public function getWords():Null<Array<String>> {
        if (!hasName()) {
            return null;
        }
        else if (_wl == null) {
            var words = new Array();
            var tree = SimpleWordLexer.lex(getName());
            for (token in tree) {
                switch ( token ) {
                    case TkWord(word):
                        words.push( word );

                    case TkCompound(wl):
                        words.push(wl.join('-'));

                    default:
                        null;
                }
            }
            return _wl = words;
        }
        else {
            return _wl;
        }
    }

    public function getWord(index: Int):Null<String> {
        var wl = getWords();
        if (!wl.hasContent())
            return null;
        return wl[index];
    }

    public function firstWord(?text: String):Null<String> {
        return getWord( 0 );
    }

    public static function firstWords(all: Array<Mark>):Array<String> {
        var results = [];
        for (m in all) {
            var fw = m.firstWord();
            if (fw != null) {
                results.push( fw );
            }
        }
        return results;
    }

    public static function nfirstWords(all:Array<Mark>, ?mutateWord:String->String):Dict<String, Int> {
        if (mutateWord == null) 
            mutateWord = FunctionTools.identity;
        var result:Dict<String, Int> = new Dict();
        var fwl = firstWords( all ).map( mutateWord );
        inline function add(w:String, n:Int=1) {
            if (result.exists( w ))
                result[w] += n;
            else 
                result[w] = n;
        }
        for (w in fwl) {
            add( w );
        }
        return result;
    }

    public static function markNthWordIndexOf(all:Array<Mark>, mark:Mark, n:Int, ?mutateWord:String->String):Int {
        if (mutateWord == null)
            mutateWord = FunctionTools.identity;
        var targetWord = mark.getWord( n );
        if (targetWord == null)
            return -1;

        var wi:Int = 0;
        for (m in all) {
            var nw = m.getWord( n );
            if (nw != null) {
                if (m == mark) {
                    return ++wi;
                }
                else if (nw == targetWord) {
                    ++wi;
                }
            }
        }
        return -1;
    }

/* === Instance Fields === */

    public var type: MarkType;
    public var time: Float;

    private var _wl:Null<Array<String>> = null;

/* === Static Methods === */

    /**
      * convert a MarkType to a JSON-object
      */
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
                    case SceneBegin: 0;
                    case SceneEnd: 1;
                }));
                o.set('n', name);
        }
        return o;
    }

    /**
      * convert a MarkType JSON-object back to the MarkType
      */
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
                    return MarkType.Scene((switch ( id ) {
                        case 0: SceneBegin;
                        case 1: SceneEnd;
                        case other: throw 'Error: Invalid SceneMarkType-id "$other"';
                    }), name);

                default:
                    throw 'Invalid Object configuration';
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
