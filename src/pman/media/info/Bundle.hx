package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.math.*;

import gryffin.display.Image;

import pman.async.*;
import pman.async.tasks.*;

import tannus.math.TMath.*;
import electron.Tools.*;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.IteratorTools;

class Bundle {
    /* Constructor Function */
    public function new(track : Track):Void {
        this.track = track;
        this.title = track.title;
        this.path = Bundles.assertBundlePath( title );

        _ic = new Map();
        tgee = new EventDispatcher();
        @:privateAccess
            tgee.__checkEvents = false;
    }

/* === Instance Methods === */

    /**
      * get the thumbnail for [this] track
      */
    public function getThumbnail(size : String):Promise<Image> {
        return Promise.create({
            var d = asizeDimensions( size );
            var res = filter.fn(_.thumb && _.set == null && _.time == null && (_.size.w == d.w && _.size.h == d.h));
            if (res.length == 0) {
                var task = new GenerateThumbnail(track, size);
                task.run(function(?error, ?path) {
                    if (error != null)
                        throw error;
                    else if (path != null) {
                        return Image.load('file://' + path);
                    }
                });
            }
            else {
                defer(function() {
                    return get(res[0]);
                });
            }
        });
    }

    /**
      * get list of thumbnail files
      */
    public function getAllThumbnails():Array<BundleItem> {
        return filter(function(i) {
            // thumbnail that is not part of a set
            return (i.thumb && i.set == null);
        });
    }

    /**
      * create an item
      */
    public function item(size:String, ?time:Float, thumb:Bool=false, ?set:Array<Int>):BundleItem {
        return {
            time: time,
            size: asizeDimensions( size ),
            set: (set != null ? {i:set[0],n:set[1]} : null),
            thumb: thumb
        };
    }

    /**
      * get an Image from an item
      */
    public function get(id : BundleItem):Null<Image> {
        var name = getNameForId( id );
        if (_ic.exists( name )) {
            return _ic[name];
        }
        else {
            return _ic[name] = Image.load('file://' + subpath( name ));
        }
    }

    /**
      * get a thumbnail list
      */
    public function getThumbs(n:Int, size:String):Null<Thumbs> {
        if (hasThumbnails(n, size)) {
            return new Thumbs(this, n, size);
        }
        else return null;
    }

    /**
      * await a thumbnail set becoming available, should it be unavailable upon request
      */
    public function awaitThumbs(count:Int, size:String, handler:Thumbs->Void):Void {
        onThumbsGenerated(count, size, function(_) {
            defer(function() {
                var thumbs = getThumbs(count, size);
                defer(handler.bind(thumbs));
            });
        });
    }

    /**
      * remove an item from [this] Bundle
      */
    public function remove(id : BundleItem):Void {
        var name = getNameForId( id );
        _ic.remove( name );
        try {
            FileSystem.deleteFile(subpath( name ));
        }
        catch (error : Dynamic) {
            return ;
        }
    }

    /**
      * get all items with the given size
      */
    public function getBySize(size : String):Array<BundleItem> {
        var ss = asizeDimensions( size );
        inline function eq(x, y)
            return (x.w == y.w && x.h == y.h);
        return filter.fn(eq(ss, _.size));
    }

    /**
      * get all items that belong to a set of the given size
      */
    public function getBySetSize(count : Int):Array<BundleItem> {
        return filter(function(i : BundleItem) {
            return (i.set != null && i.set.n == count);
        });
    }

    /**
      * get all of the bundle items of a set
      */
    public function getSetItems(count:Int, size:String):Array<BundleItem> {
        var ss = asizeDimensions( size );
        inline function eq(x, y)
            return (x.w == y.w && x.h == y.h);
        return filter(function(i : BundleItem) {
            return (eq(ss, i.size) && (i.set != null && i.set.n == count));
        });
    }

    /**
      * get all items at the given time
      */
    public function getByTime(time:Float, threshold:Float=0.88):Array<BundleItem> {
        return filter.fn(_.time.almostEquals(time, threshold));
    }

    /**
      * get the path to the given item
      */
    public function pathTo(item : BundleItem):Path {
        return subpath(getNameForId( item ));
    }

    /**
      * filter out a subset of [this] Bundle's items
      */
    public function filter(pred : BundleItem->Bool):Array<BundleItem> {
        var res = [];
        for (i in items())
            if (pred( i ))
                res.push( i );
        return res;
    }

    /**
      * filter out a subset of [this] Bundle's items by paths
      */
    public function ffilter(pred : Path->Bool):Array<BundleItem> {
        return subpaths().filter( pred ).map.fn(getItemId(_.toString()));
    }

    /**
      * iterate over all 'items' 
      */
    public function items():Iterator<BundleItem> {
        return fnames().iterator().map(getItemId);
    }

    /**
      * obtain list of subpaths of the bundle
      */
    public function subpaths():Array<Path> {
        return fnames().map( subpath );
    }

    /**
      * get list of file names
      */
    public function fnames():Array<String> {
        return Fs.readDirectory( path );
    }

    /**
      * get subpath of [this]
      */
    public function subpath(s : String):Path return path.plusString( s );

    /**
      * check for existance of a file named [n] in the [path] directory
      */
    public function fexists(n : String):Bool {
        return Fs.exists(subpath( n ));
    }

    /**
      * generate and retrieve a thumbnail set 
      */
    public function genThumbs(n:Int, size:String, ?done:Cb<Array<Path>>):Void {
        if (done == null) {
            done = untyped fn([e,v]=>null);
        }
        track.getData(function(?e, ?v) {
            if (hasThumbnails(n, size)) {
                defer(function() {
                    done(null, []);
                });
            }
            else {
                var task = new pman.async.tasks.GenerateThumbnails(track, n, size);
                task.run(function(?error, ?paths) {
                    if (error != null) {
                        done(error, null);
                    }
                    else if (paths != null) {
                        trace(paths.map.fn(_.name));
                        _announceThumbsGenerated(n, size, paths);
                    }
                    else {
                        trace('no paths were obtained. this be some wonky shit');
                    }
                });
                defer(function() {
                    done(null, null);
                });
            }
        });
    }

    /**
      * check for existing thumbnails
      */
    public function hasThumbnails(count:Int, size:String):Bool {
        var npl = thumbnailFileNames(count, size).map.fn(_[1]);
        trace( npl );
        for (name in npl) {
            if (!fexists( name )) {
                return false;
            }
        }
        return true;
    }

    /**
      * get the list of paths that point to the desired thumbnail files
      */
    public function thumbnailPaths(count:Int, size:String):Array<Path> {
        var res = [], npl = thumbnailFileNames(count, size);
        for (np in npl) {
            var pushed:Bool = false;
            for (n in np) {
                if (fexists( n )) {
                    res.push(subpath( n ));
                    pushed = true;
                    break;
                }
            }
            if ( !pushed )
                throw 'WTBF?';
        }
        return res;
    }

    /**
      * get dimensions of thumbnail from 'size' string
      */
    public function sizeDimensions(s : String):Rectangle {
        var dim = new Rectangle(0, 0, track.data.meta.video.width, track.data.meta.video.height);
        if (s.has( 'x' )) {
            var vec = [s.before('x'), s.after('x')];
            switch ( vec ) {
                case [x, y] if (x.isNumeric() && y.isNumeric()):
                    return new Rectangle(0, 0, Std.parseFloat( x ), Std.parseFloat( y ));

                case ['?', y] if (y.isNumeric()):
                    return dim.scaled(null, Std.parseFloat( y ));

                case [x, '?'] if (x.isNumeric()):
                    return dim.scaled(Std.parseFloat( x ), null);

                default:
                    throw 'WTBF';
            }
        }
        else if (s.endsWith('%')) {
            var perc = new tannus.math.Percent(Std.parseFloat(s.before('%')));
            return dim.percentScaled( perc );
        }
        else {
            throw 'WTBF';
        }
    }

    /**
      * gets sizeDimensions as an anonymous object
      */
    private function asizeDimensions(s : String):{w:Int, h:Int} {
        var r = sizeDimensions( s );
        return {w:floor(r.w), h:floor(r.h)};
    }

    /**
      * get the timemarks
      */
    public function getTimemarks(count : Int):Array<Float> {
        var step:Float = (track.data.meta.duration / (count + 1.0));
        var times = [];
        for (i in 1...(count + 1)) {
            times.push(i * step);
        }
        return times;
    }

    /**
      * thumbnail size as String from Rectangle
      */
    private inline function strDimension(d : Rectangle):String {
        return (floor( d.width ) + 'x' + floor( d.height ));
    }

    /**
      * get a list of the names of the files that would represent a set of thumbnails generated using the given parameters
      */
    public function thumbnailFileNames(count:Int, size:String):Array<Array<String>> {
        var sd = sizeDimensions( size ), tml = getTimemarks( count ), ss = strDimension( sd );
        var res = [];
        for (i in 0...tml.length) {
            var time = tml[i];
            res.push([
                '$ss@$time.png',
                't[${i+1}:$count]$ss@$time.png'
            ]);
        }
        return res;
    }

    /**
      * parse a BundleItemId object from the given item name
      */
    public function getItemId(name : String):BundleItem {
        var time:Null<Float> = null;
        var thumb:Bool = false;
        var set:Null<{i:Int,n:Int}> = null;
        var size:Array<Int> = [0,0];
        if (name.has('@')) {
            time = Std.parseFloat(name.after('@').before('.png'));
            name = name.before('@');
        }
        if (name.startsWith('t')) {
            thumb = true;
            name = name.after('t');
            if (name.startsWith('[')) {
                set = name.after('[').before(']').split(':').map(Std.parseInt).with([i,n], {i:i,n:n});
                name = name.after(']');
            }
        }
        size = name.split('x').map(Std.parseInt);
        return {
            time: time,
            thumb: thumb,
            set: set,
            size: {w:size[0], h:size[1]}
        };
    }

    /**
      * create a filename string from the given 'item id'
      */
    public function getNameForId(id : BundleItem):String {
        var s = '${id.size.w}x${id.size.h}';
        if (id.time != null) {
            s += '@${id.time}';
        }
        if (id.set != null) {
            s = ('t[${id.set.i}:${id.set.n}]' + s);
        }
        else if ( id.thumb ) {
            s = ('t' + s);
        }
        s += '.png';
        return s;
    }

    /**
      * announce to anything listening that a thumbnail set has just been generated
      */
    private function _announceThumbsGenerated(count:Int, size:String, paths:Array<Path>):Void {
        tgee.dispatch('${strDimension(sizeDimensions(size))}:$count', paths);
    }

    /**
      * wait for a thumbnail set to be generated and ready, without initiating the generation of said thumbnail set
      */
    public function onThumbsGenerated(count:Int, size:String, handler:Array<Path>->Void):Void {
        tgee.on('${strDimension(sizeDimensions(size))}:$count', handler);
    }

/* === Instance Fields === */

    public var track : Track;
    public var title : String;
    public var path : Path;

    private var _ic : Map<String, Image>;

    // thumb-generation event emitter
    private var tgee : EventDispatcher;
}

typedef BundleItem = {
    ?set: {i:Int, n:Int},
    size: {w:Int, h:Int},
    ?time: Float,
    thumb: Bool
};
