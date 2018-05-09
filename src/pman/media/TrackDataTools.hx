package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.dict.DictKey;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.http.Url;

import pman.bg.media.*;
import pman.bg.media.MediaRow;
import pman.bg.media.MediaDataDelta;
import pman.bg.media.MediaDataSource;
import pman.media.TrackData2;

import Slambda.fn;
import haxe.extern.EitherType;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import Reflect.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.ds.SortingTools;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.math.TMath;
using pman.bg.URITools;
using pman.bg.PathTools;
using pman.bg.DictTools;
using pman.media.MediaTools;
using tannus.html.JSTools;

@:keep
@:expose("$tdtools")
class TrackDataTools {
    public static var _type:Class<TrackData2> = {TrackData2;};
    public static var internal:Class<TdiTools> = {TdiTools;};
    public static var mediaDataSource:Class<MdsTools> = {MdsTools;};
    public static var nullableMediaDataSource:Class<NmdsTools> = {NmdsTools;};
    public static var mediaRow:Class<MediaRowTools> = {MediaRowTools;};
}

@:allow( pman.media.TrackData2 )
@:access( pman.media.TrackData2 )
// TrackData Internal Tools
class TdiTools {
    /**
      * delete multiple fields from a given object
      */
    private static function deleteFields(o:Dynamic, names:Array<String>) {
        for (n in names) {
            o.nativeArrayDelete( n );
        }
    }

    /**
      * utility method for keeping the ugliness of the null checks and whatnot out of TrackData's main code
      */
    private static function _withField<TProp,TRes>(self:TrackData2, prop:String, body:TProp->TRes):TRes {
        self.au();
        if (self.hasOwnProperty( prop )) {
            return body(self.nativeArrayGet(prop));
        }
        else {
            throw TrackDataError.ErrInvalidAccess( prop );
        }
    }

    public static function nonNullFields(o: Dynamic):Array<String> {
        return fields( o ).filter.fn(field(o, _) != null);
    }

    /**
      * 
      */
    public static function propList(a: Array<String>):Array<String> {
        return order(
            uniqs(a.filter(x -> x.hasContent())),
            Reflect.compare
        );
    }


    @:generic
    public static function toSet<T:DictKey>(items: Array<T>):Set<T> {
        var set:Set<T> = new Set();
        set.pushMany( items );
        return set;
    }

    @:generic
    public static function uniques<T:DictKey>(items: Array<T>):Array<T> return toSet(items).toArray();
    private static function uniqs(a: Array<String>):Array<String> return uniques( a );

    /**
      * sort [items], then return it
      */
    public static function order<T>(items:Array<T>, compare:T->T->Int):Array<T> {
        haxe.ds.ArraySort.sort(items, compare);
        return items;
    }
}

// Media Data Source Tools
class MdsTools {
    public static function clone(src:MediaDataSource, depth:Int=1):MediaDataSource {
        return (switch ( src ) {
            case Complete(data): Complete(cloneState(data, depth));
            case Create(data): Create(cloneState(data, depth));
            case Partial(props, data): Partial(props.copy(), cloneState(data, depth));
            case Empty: Empty;
        });
    }

    /**
      * shallowly copy all non-null data from [y] onto [x], then return [x]
      */
    public static function extend(x:MediaDataSource, y:MediaDataSource):MediaDataSource {
        switch ([x, y]) {
            // if either argument is null
            case [_, null], [null, _]:
                throw 'Error: Cannot "extend" with a null value';

            // if either argument is Empty
            case [_, Empty], [Empty, _]:
                throw 'Error: Cannot "extend" with Empty';

            // if both arguments are proper MediaDataSource values that we can work with
            case [Create(dx)|Complete(dx)|Partial(_, dx), Create(dy)|Complete(dy)|Partial(_, dy)]:
                var data = extendState(dx, dy);
                var names:Array<String> = TdiTools.propList(TdiTools.nonNullFields( data.current ));
                if (names.compare( TrackData2._all_ )) {
                    return Complete( data );
                }
                else {
                    return Partial(names, data);
                }

            // no specified action for anything else
            default:
                throw 'Error: Unexpected input for "extend"';
        }
    }

    public static function cloneState(state:MediaDataSourceState, depth:Int=1):MediaDataSourceState {
        return {
            row: (state.row != null ? MediaRowTools.clone( state.row ) : null),
            current: NmdsTools.clone(state.current, depth),
            initial: NmdsTools.clone(state.initial, depth)
        };
    }

    public static function extendState(state:MediaDataSourceState, other:MediaDataSourceState):MediaDataSourceState {
        if (other.row != null)
            state.row = other.row;
        state.current = NmdsTools.extend(state.current, other.current);
        state.initial = NmdsTools.extend(state.initial, other.initial);
        return state;
    }
}

class NmdsTools {
    /**
      * shallowly copy the non-null fields from [y] onto [x], then return [x]
      */
    public static function extend(x:NullableMediaDataState, y:NullableMediaDataState):NullableMediaDataState {
        //echo(untyped ['NullableMediaDataState.extend', x.deepCopy());
        var v: Dynamic;
        var names:Array<String> = fields( y );
        for (name in names) {
            v = O.fieldGet(y, name);
            echo({
                property: name,
                values: [O.fieldGet(x, name), O.fieldGet(y, name)],
                yHas: hasField(y, name),
                xHas: hasField(x, name)
            });
            
            if (v != null) {
                O.fieldSet(x, name, v);
            }
        }
        //echo( x );
        return x;
    }

    /**
      create and return a deep copy of [d]
     **/
    public static function clone(d:NullableMediaDataState, depth:Int=1):NullableMediaDataState {
        depth = depth.clamp(0, 2);
        
        var i:NullableMediaDataState = Reflect.copy( d );

        // purely shallow-copy
        if (depth == 0) {
            return i;
        }

        // copy 'meta' field
        if (i.meta != null) {
            i.meta = d.meta.clone();
        }

        // copy 'attrs' field
        if (i.attrs != null) {
            i.attrs = d.attrs.copy();
        }

        // copy 'tags' field
        if (i.tags != null) {
            //i.tags = (depth > 1 ? i.tags.map.fn(_.clone()) : i.tags.copy());
            i.tags = d.tags.copy();
            if (depth > 1) {
                i.tags = i.tags.map.fn(_.clone());
            }
        }

        // copy 'actors' field
        if (i.actors != null) {
            i.actors = d.actors.copy();
            if (depth > 1) {
                i.actors = i.actors.map.fn(_.clone());
            }
        } 

        // copy 'marks' field
        if (i.marks != null) {
            i.marks = d.marks.copy();
            if (depth > 1) {
                i.marks = i.marks.map(mark->mark.clone());
            }
        }

        return i;
    }
}

class MediaRowTools {
    public static function clone(row: MediaRow):MediaRow {
        var c:MediaRow = Reflect.copy( row );
        if (c.data != null)
            c.data = MdrTools.clone( c.data );
        return c;
    }
}

class MdrTools {
    public static function clone(d: MediaDataRow):MediaDataRow {
        return d.with({
            actors: nac(_.actors),
            attrs: noc(_.attrs),
            tags: nac(_.tags),
            marks: nac(_.marks),
            meta: noc(_.meta),

            views: _.views,
            starred: _.starred,
            rating: _.rating,
            contentRating: _.contentRating,
            channel: _.channel,
            description: _.description
        });
    }

    private static inline function nac<T>(a: Null<Array<T>>):Null<Array<T>> return (a != null ? a.copy() : null);
    private static inline function noc<T>(object:Null<T>):Null<T> {
        return (object != null ? Reflect.copy( object ) : null);
    }
}

// Object Tools
class O {
    public static function fieldGet<T>(o:Dynamic, name:String):Null<T> {
        return Reflect.field(o, name);
    }

    public static function fieldSet<T>(o:Dynamic, name:String, value:T):T {
        Reflect.setField(o, name, value);
        return fieldGet(o, name);
    }

    public static function fieldDelete(o:Dynamic, name:String):Bool {
        return Reflect.deleteField(o, name);
    }
}
