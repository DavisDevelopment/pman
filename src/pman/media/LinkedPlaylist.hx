package pman.media;

import tannus.io.*;
import tannus.ds.Promise;
import tannus.sys.Path;
import tannus.http.Url;

import haxe.Serializer;
import haxe.Unserializer;
import electron.Tools.defer;

import pman.core.*;
import pman.media.PlaylistChange;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

class LinkedPlaylist {
    /* Constructor Function */
    public function new(?tracks : Array<Track>):Void {
        track = null;
        parentList = null;
        length = 0;
        changeEvent = new Signal();

        if (tracks != null) {
            for (t in tracks) {
                push(t.clone());
            }
        }
    }

/* === Instance Methods === */

    /**
      * concatenate
      */
    public function concat(other : LinkedPlaylist):LinkedPlaylist {
        var tracks = toArray().concat(other.toArray());
        return new LinkedPlaylist( tracks );
    }

    /**
      * get by index and shit
      */
    @:deprecated
    public function get(index : Int):Null<Track> {
        var i = 0;
        for (t in this) {
            if (i == index) {
                return t;
            }
            i++;
        }
        return null;
    }

    /**
      * get by offset
      */
    public function getByOffset(t:Track, offset:Int):Null<Track> {
        t = local( t );
        if (t == null) {
            return null;
        }
        else {
            var o:Int = 0;
            if (offset == 0) {
                return t;
            }
            else if (offset > 0) {
                while (o < offset) {
                    if (t.next == null) {
                        return null;
                    }
                    else {
                        t = t.next;
                        o++;
                    }
                }
                return t;
            }
            else if (offset < 0) {
                while (o > offset) {
                    var bt = before( t );
                    if (bt == null) {
                        return null;
                    }
                    else {
                        t = bt;
                        o--;
                    }
                }
                return t;
            }
        }
        return null;
    }

    /**
      * create and return a deep-copy of [this]
      */
    public function clone():LinkedPlaylist {
        var copy = new LinkedPlaylist();
        if (first() == null) {
            return copy;
        }
        else {
            copy.track = track.clone( true );
            return copy;
        }
    }

    /**
      * Iterate over [this]
      */
    public function iterator():Iterator<Track> {
        return new LinkedPlaylistIterator( this );
    }

    /**
      * add the given Track to the end of the List
      */
    public function push(t:Track, report:Bool=true):Void {
        t.next = null;
        if (track == null) {
            track = t;
        }
        else {
            last().next = t;
        }
        length++;
        if ( report )
            change(PCPush( t ));
    }

    /**
      * remove and return the last Track
      */
    public function pop(report:Bool=true):Null<Track> {
        if (track == null) {
            return null;
        }
        else {
            var c = before(last());
            if (c != null) {
                var result = c.next;
                c.next = null;
                length--;
                if ( report )
                    change(PCPop( result ));
                return result;
            }
            else {
                return null;
            }
        }
    }

    /**
      * insert [a] after [b]
      */
    public function insertAfter(track:Track, child:Track, report:Bool=true):Void {
        if (!isEmpty()) {
            var lc = local( child );
            if (lc != null) {
                var tmp = lc.next;
                lc.next = track;
                track.next = tmp;
                length++;
                if ( report ) {
                    change(PCInsertAfter(track, child));
                }
            }
        }
    }

    /**
      * insert [a] before [b]
      */
    public function insertBefore(track:Track, child:Track, report:Bool=true):Void {
        var lc = local( child );
        if (lc != null) {
            lc = before( lc );
            if (lc != null) {
                var tmp = lc.next;
                lc.next = track;
                track.next = tmp;
                length++;
                if ( report ) {
                    change(PCInsertBefore(track, child));
                }
            }
        }
    }

    /**
      * move [track] to after [child]
      */
    public function moveToAfter(track:Track, child:Track, report:Bool=true):Void {
        remove(track, false);
        insertAfter(track, child, false);
        if ( report ) {
            change(PCMoveToAfter(track, child));
        }
    }

    /**
      * move [track] to before [child]
      */
    public function moveToBefore(track:Track, child:Track, report:Bool=true):Void {
        remove(track, false);
        insertBefore(track, child, false);
        if ( report ) {
            change(PCMoveToBefore(track, child));
        }
    }

    /**
      * check whether [this] Playlist has the given Track
      */
    public inline function has(t : Track):Bool {
        return (local( t ) != null);
    }

    /**
      * remove the given Track
      */
    public function remove(track:Track, report:Bool=true):Bool {
        var removed = false;
        if (isEmpty()) {
            return removed;
        }
        else {
            var lt = local( track );
            if (lt == null) {
                return removed;
            }
            else {
                var bt = before( lt );
                var at = lt.next;
                if (bt != null) {
                    lt.next = null;
                    bt.next = at;
                    removed = true;
                    length--;
                    if ( report ) {
                        change(PCRemove( lt ));
                    }
                }
                return removed;
            }
        }
    }

    /**
      * clear [this] List
      */
    public function clear(report:Bool=true):Void {
        track = null;
        length = 0;
        if ( report ) {
            change( PCClear );
        }
    }

    /**
      * get the first item of [this] List
      */
    public inline function first():Null<Track> {
        return track;
    }

    /**
      * check whether this is empty
      */
    public inline function isEmpty():Bool {
        return (first() == null);
    }

    /**
      * get the last item of [this] List
      */
    public function last():Null<Track> {
        if (first() == null) {
            return null;
        } 
        else {
            var c = first();
            while (c.next != null) {
                c = c.next;
            }
            return c;
        }
    }

    /**
      * get the Track that occurs just before the given one
      */
    public function before(t : Track):Null<Track> {
        if (first() == null) {
            return null;
        }
        else if (first().equals( t )) {
            return null;
        }
        else {
            var c = first();
            while (c.next != null) {
                if (c.next.equals( t )) {
                    return c;
                }
                c = c.next;
            }
            return null;
        }
    }

    /**
      * get the local instance of the given Track
      */
    public function local(track : Track):Null<Track> {
        for (t in this) {
            if (t.equals( track )) {
                return t;
            }
        }
        return null;
    }

    /**
      * convert [this] to an Array
      */
    public function toArray():Array<Track> {
        return [for (t in this) t];
    }

    /**
      * filter [this]
      */
    public function filter(f : Track->Bool):LinkedPlaylist {
        var result = new LinkedPlaylist();
        for (t in this) {
            if (f( t )) {
                result.push( t );
            }
        }
        return result;
    }

    /**
      * map [this]
      */
    public function map<T>(f : Track->T):Array<T> {
        return [for (t in this) f( t )];
    }

    /**
      * convert to JSON array
      */
    public function toJSON():Array<String> {
        return map.fn( _.uri );
    }

    /**
      * dispatch an event
      */
    private function change(type : PlaylistChange):Void {
        defer(changeEvent.call.bind( type ));
    }

/* === Instance Fields === */

    public var length(default, null): Int;
	public var changeEvent : Signal<PlaylistChange>;
	public var parentList : Null<LinkedPlaylist>;

    private var track : Null<Track>;

/* === Static Methods === */

    public static function fromJSON(dataStrings : Array<String>):LinkedPlaylist {
		var tracks:Array<Track> = dataStrings.map.fn(_.parseToTrack());
		return new LinkedPlaylist( tracks );
    }
}

class LinkedPlaylistIterator {
    private var p : LinkedPlaylist;
    private var c : Null<Track>;
    public function new(lp : LinkedPlaylist):Void {
        p = lp;
        c = p.first();
    }
    public function hasNext():Bool {
        return (c != null && c.next != null);
    }
    public function next():Track {
        return (c = c.next);
    }
}
