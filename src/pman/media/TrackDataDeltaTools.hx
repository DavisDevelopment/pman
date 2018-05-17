package pman.media;

import tannus.io.*;
import tannus.ds.*;
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
import tannus.ds.AnonTools.deepCopy;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.ds.SortingTools;
using tannus.ds.AnonTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using pman.bg.PathTools;
using pman.bg.DictTools;
using pman.media.MediaTools;

class TrackDataDeltaTools {
    /**
      convert the given MediaDataDelta into a MediaDataRowDelta
     **/
    public static function toRowDelta(d: MediaDataDelta):MediaDataRowDelta {
        // check for property
        inline function has(n: String):Bool 
            return Reflect.hasField(d, n);

        /* create deep-clone of all data held in [d] */
        //var rd:MediaDataRowDelta = Reflect.callMethod(_, _.pick, (untyped [d]).concat( TrackData._inline_ ));
        var rd:MediaDataRowDelta = (d.deepCopy( true ) : Dynamic);
        trace( rd );

        /* then redefine the properties that have a different type than the cloned data */

        // transform `d.marks` into cloneable JSON objects
        if (has('marks')) {
            var jsom = fn(_.toJson());
            rd.marks = new Delta(d.marks.current.map(jsom), d.marks.previous.map(jsom));
        }

        // copy data from `d.tags` into new array
        if (has('tags')) {
            rd.tags = d.tags.deepCopy( true );
        }

        // copy data from `d.actors` into new array
        if (has('actors')) {
            rd.actors = d.actors.deepCopy( true );
        }

        /**
          convert `d.meta` into a `Delta<A, B>` of the cloneable
          JSON objects created from mapping `_.toRaw()` across both its values
         **/
        if (has('meta')) {
            rd.meta = new Delta(d.meta.current.toRaw(), d.meta.previous.toRaw());
        }

        if (has('attrs')) {
            rd.attrs = d.attrs.copy();
        }

        return rd;
    }

    /**
      * create a MediaDataDelta object from the given TrackData, which represents the changes made to the TrackData since it was loaded
      */
    public static function trackDataDelta(data: TrackData2):Null<MediaDataDelta> {
        var state = data.getSourceData( data.source );
        if (state == null) {
            return null;
        }
        else {
            if (state.initial != null && state.current != null) {
                return dataStateDelta(
                    state.current,
                    state.initial
                    //fn(name => data.checkProperty(name))
                );
            }
            else {
                return null;
            }
        }
    }

    /**
      * compute and return the 'delta' (damage) between [cur] and [old]
      */
    public static function dataStateDelta(cur:NullableMediaDataState, old:NullableMediaDataState, ?has:String->Bool):MediaDataDelta {
        // ensure that [has] exists
        if (has == null) {
            has = (function(s: String):Bool {
                return (Reflect.hasField(cur, s) || Reflect.hasField(old, s));
            });
        }

        // create blank delta object
        var delta:MediaDataDelta = {};

        // [views]
        if (has('views') && cur.views != old.views)
            delta.views = new Delta(cur.views, old.views);

        // [starred]
        if (has('starred') && cur.starred != old.starred)
            delta.starred = new Delta(cur.starred, old.starred);

        // [rating]
        if (has('rating') && cur.rating != old.rating)
            delta.rating = new Delta(cur.rating, old.rating);

        // [contentRating]
        if (has('contentRating') && cur.contentRating != old.contentRating)
            delta.contentRating = new Delta(cur.contentRating, old.contentRating);

        // [channel]
        if (has('channel') && cur.channel != old.channel)
            delta.channel = new Delta(cur.channel, old.channel);

        // [description]
        if (has('description') && cur.description != old.description)
            delta.description = new Delta(cur.description, old.description);

        // [attrs]
        if (has('meta') && cur.meta != old.meta)
            delta.meta = new Delta(cur.meta, old.meta);

        // [attrs]
        if (has('attrs') && cur.attrs != null && old.attrs != null) {
            if (!_.isEqual(cur.attrs.toAnon(), old.attrs.toAnon())) {
                delta.attrs = DictDeltaTools.deltaFrom(cur.attrs, old.attrs);
            }
        }

        // [marks]
        if (has('marks') && cur.marks != null && old.marks != null) {
            var hasDelta:Bool = false;

            if (cur.marks.length != old.marks.length) {
                hasDelta = true;
            }
            else {
                //delta.marks = ArrayDeltaTools.deltaFrom(cur.marks, old.marks, null, ((x, y) -> x.type.equals( y.type )));
                var compareMarks = fn(Reflect.compare(_1.time, _2.time));
                cur.marks.sort( compareMarks );
                old.marks.sort( compareMarks );

                for (i in 0...cur.marks.length) {
                    if (!cur.marks[i].equals(old.marks[i])) {
                        hasDelta = true;
                        break;
                    }
                }
            }

            if ( hasDelta ) {
                delta.marks = new Delta(cur.marks, old.marks);
            }
        }

        // [tags]
        if (has('tags') && cur.tags != null && old.tags != null) {
            //delta.tags = ArrayDeltaTools.deltaFrom(cur.tags, old.tags, null, ((x, y) -> x.equals( y )));
            var f = fn(_.name);
            delta.tags = new Delta(cur.tags.map(f), old.tags.map(f));
        }

        // [actors]
        if (has('actors') && cur.actors != null && old.actors != null) {
            //delta.actors = ArrayDeltaTools.deltaFrom(cur.actors, old.actors, null, ((x, y) -> x.equals( y )));
            var f = fn(_.name);
            delta.actors = new Delta(cur.actors.map(f), old.actors.map(f));
        }

        return delta;
    }
}

class ArrayDeltaTools {
    /**
      * build an ArrayDelta object by comparing the two given arrays
      */
    public static function deltaFrom<TItem, TDelta>(cur:Array<TItem>, old:Array<TItem>, ?delta:TItem->TItem->Null<TDelta>, ?compare:TItem->TItem->Bool):ArrayDelta<TItem, TDelta> {
        if (delta == null) {
            untyped {
                delta = ((x, y) -> new Delta(x, y));
            };
        }

        if (compare == null) {
            compare = fn(_1 == _2);
        }

        var items:Array<ArrayDeltaItem<TItem, TDelta>> = new Array();
        inline function add(x: ArrayDeltaItem<TItem, TDelta>) items.push( x );

        var wco = old.copy();
        var added = cur.without(old, compare);
        var removed = old.without(cur, compare);
        var persisted = cur.intersection( old );

        for (item in added) {
            add(AdiAppend( item ));
        }

        for (item in removed) {
            add(AdiRemove( item ));
        }

        var ci:Int, oi:Int;
        for (item in persisted) {
            ci = customIndexOf(cur, item, compare);
            oi = customIndexOf(old, item, compare);
            var delt = delta(cur[ci], old[oi]);
            if (delt != null) {
                add(AdiAlter(item, delt));
            }
        }

        return {
            items: items,
            src: cur
        };
    }

    /**
      * apply the given ArrayDelta to the given Array
      */
    public static function applyDelta<TItem,TDelta>(array:Array<TItem>, d:ArrayDelta<TItem,TDelta>, apply:Array<TItem>->Int->TDelta->Void, ?compare:TItem->TItem->Bool):Array<TItem> {
        if (compare == null) {
            compare = fn(_1 == _2);
        }

        // ...

        for (step in d.items) {
            switch ( step ) {
                case AdiRemove( item ):
                    array.remove( item );

                case AdiAppend( item ):
                    array.push( item );

                case AdiAlter(item, delta):
                    var index:Int = customIndexOf(array, item, compare);
                    apply(array, index, delta);

                case AdiInsert(item, index):
                    array.insert(index, item);
            }
        }

        var tmp:Array<TItem> = array.copy();
        for (index in 0...tmp.length) {
            var srcIndex:Int = customIndexOf(d.src, array[index], compare);
            tmp[srcIndex] = array[index];
        }

        return tmp;
    }

    private static function customIndexOf<T>(a:Array<T>, x:T, ?compare:T->T->Bool):Int {
        if (compare == null)
            compare = fn(_1 == _2);
        for (index in 0...a.length) {
            if (compare(a[index], x)) {
                return index;
            }
        }
        return -1;
    }
}

class DictDeltaTools {
    public static function deltaFrom(current:Dict<String, Dynamic>, original:Dict<String, Dynamic>):DictDelta {
        function order(a: Array<String>):Array<String> {
            a.sort(untyped Reflect.compare);
            return a;
        }

        var keys:Pair<Array<String>, Array<String>> = new Pair(order(original.keys().array()), order(current.keys().array()));
        var newKeys = order(keys.right.without( keys.left ));
        var delKeys = order(keys.left.without( keys.right ));
        var allKeys = order(keys.left.union( keys.right ).compact().unique());
        var items:Array<DictDeltaItem> = new Array();
        for (key in allKeys) {
            if (newKeys.has( key )) {
                items.push(DdiAdd(key, current[key]));
            }
            else if (delKeys.has( key )) {
                items.push(DdiRemove( key ));
            }
            else if (original[key] != current[key]) {
                items.push(DdiAlter(key, new Delta(current[key], original[key])));
            }
        }
        return items;
    }

    public static function dapplyDelta(d:Dict<String, Dynamic>, delta:DictDelta):Void {
        for (item in delta) {
            switch ( item ) {
                case DdiAdd(k, v):
                    d[k] = v;

                case DdiRemove( k ):
                    d.remove( k );

                case DdiAlter(k, vd):
                    d[k] = vd.current;
            }
        }
    }
    public static function oapplyDelta(d:Object, delta:DictDelta):Void {
        for (item in delta) {
            switch ( item ) {
                case DdiAdd(k, v):
                    d[k] = v;

                case DdiRemove( k ):
                    d.remove( k );

                case DdiAlter(k, vd):
                    d[k] = vd.current;
            }
        }
    }
}
