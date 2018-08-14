package pman.media.queue;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.async.*;
import tannus.async.Feed;
import tannus.stream.Stream;

import haxe.ds.Option;
import haxe.ds.Either;
import haxe.extern.EitherType;
import haxe.Constraints.Function;

import pman.bg.media.MediaType;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaFeature;
import pman.bg.media.Dimensions;

import Slambda.fn;
import tannus.math.TMath.*;

import edis.Globals.*;
//import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.IteratorTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using tannus.async.OptionTools;
using pman.media.MediaTools;

@:forward
abstract MediaQueue (MediaQueueObject) from MediaQueueObject to MediaQueueObject {
    public inline function new() {
        this = new MediaQueueObject();
    }

/* === Instance Methods === */

}

class MediaQueueObject {
    /* Constructor Function */
    public function new() {
        firstNode = null;
        lastNode = null;
        nodes = [];
        len = 0;
    }

/* === Instance Methods === */

    public function push(item: MediaQueueItem) {
        var inode = node( item );
        if (firstNode == null) {
            firstNode = inode;
            lastNode = null;
            len = 1;
            nodes = [inode];
        }
        else {
            if (lastNode != null) {
                lastNode.before( inode );
                lastNode = inode;
                nodes.push( inode );
                ++len;
            }
            else if (firstNode != null) {
                lastNode = inode;
                lastNode.after( firstNode );
                nodes.push( inode );
                ++len;
            }
            else {
                throw 'assert';
            }
        }
    }

    public function unshift(item: MediaQueueItem) {
        var inode = node( item );
        if (firstNode == null) {
            firstNode = inode;
            lastNode = null;
            len = 1;
            nodes = [inode];
        }
        else {
            firstNode.after( inode );
            firstNode = inode;
            ++len;
            nodes.unshift( inode );
        }
    }

    public function insert(pos:Int, item:MediaQueueItem) {
        //var nnode = node( item ),
        var onode = nodeAt( pos );
        if (onode == null) {
            if (pos <= 0)
                unshift( item );
            else if (pos >= len)
                push( item );
        }
        else {
            var inode = node( item );
            inode.before( onode );
            ++len;
            nodes.insert(pos, inode);
        }
    }

    public function pop():Null<MediaQueueItem> {
        return switch popNode() {
            case null: null;
            case node: node.item;
        }
    }

    public function shift():Null<MediaQueueItem> {
        return switch shiftNode() {
            case null: null;
            case node: node.item;
        }
    }

    public function remove(item: MediaQueueItem):Bool {
        return removeNode(find( item ));
    }

    @:noCompletion
    public function removeNode(n: Null<MediaQueueNode>):Bool {
        if (n == null)
            return false;

        switch [n.previous, n.next] {
            case [prev=Some(pn), next=Some(nn)]:
                pn.next = next;
                nn.previous = prev;
                n.unlink();

            case [prev=None, next=Some(nn)]:
                nn.previous = prev;
                n.unlink();
                if (n == firstNode) {
                    firstNode = nn;

                    if (nn == lastNode)
                        lastNode = null;
                }

            case [prev=Some(pn), next=None]:
                pn.next = next;
                n.unlink();

                if (n == lastNode) {
                    lastNode = pn;
                }

            case unex:
                throw 'Unexpected $unex';
        }

        --len;
        nodes.remove( n );

        return true;
    }

    @:noCompletion
    public function popNode():Null<MediaQueueNode> {
        if (lastNode == null) {
            if (firstNode == null) {
                return null;
            }
            else {
                var ret = firstNode;
                firstNode = null;
                len = 0;
                nodes = [];
                return ret;
            }
        }
        else {
            var ret = lastNode;
            switch lastNode.previous {
                case Some(secLast):
                    lastNode = secLast;
                    lastNode.next = None;
                    ret.unlink();
                    --len;
                    nodes.pop();

                case None:
                    throw 'assert';
            }
            return ret;
        }
    }

    @:noCompletion
    public function shiftNode():Null<MediaQueueNode> {
        if (firstNode != null) {
            var ret = firstNode;
            switch ret.next {
                case Some(secondNode):
                    secondNode.previous = None;
                    firstNode = secondNode;
                    if (lastNode == secondNode) {
                        lastNode = null;
                    }
                    --len;
                    nodes.shift();

                case None:
                    firstNode = null;
                    lastNode = null;
                    len = 0;
                    nodes = [];
            }

            ret.unlink();
            return ret;
        }
        else {
            return null;
        }
    }

    public inline function nodeAt(i: Int):Null<MediaQueueNode> {
        return nodes[i];
    }

    inline function node(item: MediaQueueItem):MediaQueueNode {
        return new MediaQueueNode(this, item);
    }

    public function iterator():Iterator<MediaQueueItem> {
        return new MediaQueueItemIterator(iterNodes());
    }

    public function tracks():Iterator<Track> {
        return iterator().map(item -> item.track);
    }

    /**
      iterate over nodes
     **/
    public function iterNodes(reverse:Bool=false):Iterator<MediaQueueNode> {
        if (reverse && lastNode != null) {
            return lastNode.walk(true);
        }
        else if (!reverse && firstNode != null) {
            return firstNode.walk(false);
        }
        else {
            return new MediaQueueNodeIterator(None);
        }
    }

    /**
      locate the node for the given item
     **/
    function find(item:MediaQueueItem, ?start:MediaQueueNode):Null<MediaQueueNode> {
        var it = (start != null ? start.walk(false) : iterNodes());
        for (node in it) {
            if (node.testItem( item )) {
                return node;
            }
        }
        return null;
    }

/* === Computed Instance Fields === */

    public var length(get, never): Int;
    inline function get_length() return len;

/* === Instance Fields === */

    var firstNode: Null<MediaQueueNode>;
    var lastNode: Null<MediaQueueNode>;

    var nodes: Array<MediaQueueNode>;
    var len: Int;
}

/**
  a node in the MediaQueue
 **/
class MediaQueueNode {
    /* Constructor Function */
    public function new(queue, item) {
        this.queue = queue;
        this.item = item;
        link(None, None);
    }

/* === Instance Methods === */

    public inline function link(l:Option<MediaQueueNode>, r:Option<MediaQueueNode>) {
        previous = l;
        next = r;
    }

    public inline function unlink() {
        link(None, None);
    }

    public function after(other: MediaQueueNode) {
        var tmp = other.next;
        other.next = Some(this);
        previous = Some(other);
        next = tmp;
    }

    public function before(other: MediaQueueNode) {
        var tmp = other.previous;
        other.previous = Some(this);
        next = Some(other);
        previous = tmp;
    }

    public function clone():MediaQueueNode {
        var ret = new MediaQueueNode(queue, item.clone());
        ret.link(previous, next);
        return ret;
    }

    public inline function testItem(item: MediaQueueItem):Bool {
        return (this.item == item || item == this.item);
    }

    public inline function walk(backward:Bool = false) {
        return new MediaQueueNodeIterator(Some(this), backward);
    }

/* === Instance Fields === */

    public var queue(default, null): MediaQueueObject;
    public var item(default, null): MediaQueueItem;

    public var previous: Option<MediaQueueNode>;
    public var next: Option<MediaQueueNode>;
}

class MediaQueueNodeIterator {
    var reverse: Bool;
    var node: Option<MediaQueueNode>;
    public function new(n:Option<MediaQueueNode>, back:Bool=false) {
        node = n;
        reverse = back;
    }

    public function hasNext():Bool {
        return node.isSome();
    }

    public function next():MediaQueueNode {
        var ret = node.getValue();
        if (ret == null)
            throw 'assert';
        node = reverse ? ret.previous : ret.next;
        return ret;
    }
}

class MediaQueueItemIterator {
    var i: Iterator<MediaQueueNode>;
    public function new(i) {
        this.i = i;
    }

    public inline function hasNext():Bool return i.hasNext();
    public inline function next():MediaQueueItem {
        return i.next().item;
    }
}

/**
  an item in a MediaQueue
 **/
@:forward(clone, reset)
abstract MediaQueueItem (MediaQueueItemObject) from MediaQueueItemObject to MediaQueueItemObject {
/* === Instance Methods === */

    @:to
    public inline function toTrack():Track {
        return track;
    }

    @:op(A == B)
    static inline function eqItems(a:MediaQueueItem, b:MediaQueueItem):Bool {
        return (a.track.equals( b.track ));
    }

    //@:op(A & B)
    //static inline function compareItems(a:MediaQueueItem, b:MediaQueueItem):Int {
        //return a.toTrack().compareTo(b.toTrack());
    //}

/* === Instance Fields === */

    public var track(get, never): Track;
    inline function get_track() return this.track.get();

/* === Casting/Factory Methods === */

    @:from
    public static inline function ofTrack(t: Track):MediaQueueItem return new PlainMediaQueueItem(Lazy.ofConst(t));

    //@:from
    //public static inline function ofProvider(mp: MediaProvider):MediaQueueItem {
        //return new ProviderMediaQueueItem(Lazy.ofConst(mp));
    //}

    //@:from
    //public static inline function ofSource(ms: MediaSource):MediaQueueItem {
        //return new SourceMediaQueueItem(Lazy.ofConst(ms));
    //}

    //@:from
    //public static inline function ofPath(path: Path):MediaQueueItem return ofPathLazy(Lazy.ofConst(path));

    //@:from
    //public static inline function ofUri(uri: String):MediaQueueItem {
        //return new UriMediaQueueItem(Lazy.ofConst(uri));
    //}

    //@:from
    //public static inline function ofTrackLazy(t: Lazy<Track>):MediaQueueItem {
        //return new PlainMediaQueueItem( t );
    //}

    //@:from
    //public static inline function ofProviderLazy(mp: Lazy<MediaProvider>):MediaQueueItem {
        //return new ProviderMediaQueueItem( mp );
    //}

    //@:from
    //public static inline function ofSourceLazy(ms: Lazy<MediaSource>):MediaQueueItem {
        //return new SourceMediaQueueItem( ms );
    //}

    //@:from
    //public static inline function ofPathLazy(path: Lazy<Path>):MediaQueueItem {
        //return new PathMediaQueueItem( path );
    //}

    //@:from
    //public static inline function ofUriLazy(uri: Lazy<String>):MediaQueueItem {
        //return new UriMediaQueueItem( uri );
    //}
}

interface MediaQueueItemObject {
    //function get_track(): Track;
    function clone(): MediaQueueItem;
    function reset(): MediaQueueItem;

    var track(default, null): Lazy<Track>;
}

class MediaQueueItemBase {
/* === Instance Methods === */

    //public function clone():MediaQueueItem {
        //throw 'Not implemented';
    //}

    //public function reset():MediaQueueItem {
        //throw 'Not implemented';
    //}

/* === Instance Fields === */

    public var track(default, null): Lazy<Track>;
}

class PlainMediaQueueItem extends MediaQueueItemBase implements MediaQueueItemObject {
    /* Constructor Function */
    public function new(track: Lazy<Track>) {
        this.track = track;
    }

    public function clone():MediaQueueItem {
        return new PlainMediaQueueItem( track );
    }

    public function reset():MediaQueueItem {
        return clone();
    }
}

//class ProviderMediaQueueItem extends PlainMediaQueueItem {
    //public function new(provider: Lazy<MediaProvider>) {
        //super((this.provider = provider).flatMap(function(mp: MediaProvider) {
            //return (function() {
                //return new Track( mp );
            //});
        //}));
    //}

    //override function clone():MediaQueueItem {
        //return new PlainMediaQueueItem(track.get());
    //}

    //public var provider(default, null): Lazy<MediaProvider>;
//}

//class SourceMediaQueueItem extends ProviderMediaQueueItem {
    //public function new(source: Lazy<MediaSource>) {
        //super((this.source = source).flatMap(function(src: MediaSource) {
            //return (function() {
                //return src.toMediaProvider();
            //});
        //}));
    //}

    //public var source(default, null): Lazy<MediaSource>;
//}

//class UriMediaQueueItem extends SourceMediaQueueItem {
    //public function new(uri: Lazy<String>) {
        //super(uri.map(function(uri: String) {
            //if (uri.isUri()) {
                //var ret = uri.toMediaSource();
                //if (ret == null)
                    //throw 'assert';
                //return ret;
            //}
            //else {
                //throw 'assert';
            //}
        //}));
    //}
//}

//class PathMediaQueueItem extends SourceMediaQueueItem {
    //public function new(path: Lazy<Path>) {
        //super(path.map(function(path: Path) {
            //return path.toMediaSource();
        //}));
    //}
//}
