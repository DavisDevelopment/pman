package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.geom.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.math.*;

import gryffin.display.Image;

import pman.async.*;
import pman.async.tasks.*;
import pman.media.info.BundleItemType;

import haxe.Json;

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
      * get a snapshot item
      */
    public function getSnapshot(time:Float, ?size:String):Promise<BundleItem> {
        if (size == null) {
            size = '100%';
        }

        return Promise.create({
            var dim = sizeDimensions( size );
            var res = findSnapshot(time, size);
            if (res == null) {
                var task = new GenerateBundleSnapshot(track, size, time);
                task.generate()
                    .then(function(path : Path) {
                        return new BundleItem(this, path.name);
                    })
                    .unless(function(error) {
                        throw error;
                    });
            }
            else {
                defer(function() {
                    return res;
                });
            }
        });
    }

    /**
      * get an Array of snapshots
      */
    public function getMultipleSnapshots(times:Array<Float>, ?size:String):ArrayPromise<BundleItem> {
        if (size == null) {
            size = '10%';
        }

        return Promise.create({
            // parse actual dimensions from [size]
            var dim = sizeDimensions( size );
            // create variable to hold BundleItem results
            var items:Array<BundleItem> = new Array();
            // create variable to hold timemarks for which no BundleItem was found
            var missing_times = new Array();
            // iterate over given times
            for (time in times) {
                // check for pre-existing snapshot at [time]
                var pess = findSnapshot(time, size);
                // if one is found
                if (pess != null) {
                    // add it to the results
                    items.push( pess );
                }
                // if it is missing
                else {
                    // mark it as such
                    missing_times.push( time );
                }
            }

            // create list of steps
            var tasks:Array<VoidAsync> = new Array();

            // queue generation of missing snapshots
            tasks.push(function(next : VoidCb) {
                // create Task instance
                var gen = new GenerateBundleSnapshots(track, missing_times, size);
                
                // run the task
                gen.run(function(?error, ?paths) {
                    if (error != null) {
                        @ignore return next( error );
                    }
                    // if [paths] were obtained
                    else if (paths != null) {
                        // convert [paths] to BundleItems
                        for (path in paths) {
                            items.push(new BundleItem(this, path.name));
                        }
                        // asynchronously continue
                        defer(next.void());
                    }
                    else {
                        @ignore return next('Error: No data returned by GenerateBundleSnapshots');
                    }
                });
            });

            // queue sort operation
            tasks.push(function(next) {
                // reorder [items]
                items.sort(function(a, b) {
                    @ignore return Reflect.compare(a.getTime(), b.getTime());
                });
                // ensure asynchronicity
                defer(function() {
                    next();
                });
            });

            // execute each [tasks] in order
            VoidAsyncs.series(tasks, function(?error) {
                if (error != null) {
                    throw error;
                }
                else {
                    return items;
                }
            });
        }).array();
    }

    /**
      * get a snapshot path
      */
    public function getSnapshotPath(time:Float, ?size:String):Promise<Path> {
        return getSnapshot(time, size).transform.fn(_.getPath());
    }

    /**
      * get path to snapshot item
      */
    public function getPathToSnapshot(time:Float, size:String):Path {
        var dim = sizeDimensions( size );
        return path.plusString('s${dim.toString()}@$time.png');
    }

    /**
      * get path to individual preview
      */

    /**
      * watch [this] Bundle for changes made to its contents
      */
    public function watch(handler : BundleItem->Void):Void {
        tgee.on('change', handler);

        if (_watcher == null) {
            _watcher = tannus.node.Fs.watch(path, function(type, filename) {
                trace( filename );
                if (isBundleItemName( filename )) {
                    var item:BundleItem = new BundleItem(this, subpath( filename ).name);

                    tgee.dispatch('change', item);
                }
            });
        }
    }

    /**
      * stop responding to changes made to the bundle
      */
    public function unwatch(?handler : BundleItem->Void):Void {
        tgee.off('change', handler);
        if (_watcher != null && !tgee.hasListener('change', handler)) {
            _watcher.close();
            _watcher = null;
        }
    }

    /**
      * get list of snapshot files
      */
    public function getSnapshots(?f : BundleItem->Bool):Array<BundleItem> {
        return filter(function(item) {
            return (item.isSnapshot() && (f != null ? f( item ) : true));
        });
    }

    /**
      * get all snapshot files
      */
    public inline function getAllSnapshots():Array<BundleItem> return getSnapshots();

    /**
      * get snapshots by size
      */
    public function getSnapshotsBySize(size : String):Array<BundleItem> {
        var dim = sizeDimensions( size );
        return getSnapshots.fn(_.getDimensions().equals(dim));
    }

    /**
      * get snapshots by time
      */
    public function getSnapshotsByTime(time:Float, ?threshold:Float):Array<BundleItem> {
        return getSnapshots.fn(i=>i.getTime().ternary(threshold!=null?_.almostEquals(time, threshold):_==time, false));
    }

    /**
      * get snapshots by time-range
      */
    public function getSnapshotsByTimeRange(time_min:Float, time_max:Float) {
        return getSnapshots.fn(i=>i.getTime().ternary(_.inRange(time_min, time_max), false));
    }

    /**
      * get the first item for which [test] returns true
      */
    public function find(test : BundleItem->Bool):Maybe<BundleItem> {
        for (item in items()) {
            if (test( item )) {
                return item;
            }
        }
        return null;
    }

    /**
      * 'find' and snapshot item
      */
    public function findSnapshot(time:Float, ?size:String):Maybe<BundleItem> {
        if (size == null)
            size = '100%';
        var dim = sizeDimensions( size );
        return find(function(item) {
            return (
                item.isSnapshot() &&
                (item.getTime().ternary(_ == time, false)) &&
                (item.getDimensions().equals( dim ))
            );
        });
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
      * remove an item from [this] Bundle
      */
    public function remove(id : BundleItem):Void {
        var name = getNameForId( id );
        _ic.remove( name );
        id.delete();
    }

    /**
      * get all items with the given size
      */
    public function getBySize(size : String):Array<BundleItem> {
        var ss = sizeDimensions( size );
        return filter(function(item) {
            var itemSize = item.getDimensions();
            return (itemSize != null ? itemSize.equals( ss ) : false);
        });
    }

    /**
      * get all items that belong to a set of the given size
      */
    public function getBySetSize(count : Int):Array<BundleItem> {
        return [];
        //return filter(function(i : BundleItem) {
            //return (i.set != null && i.set.n == count);
        //});
    }

    /**
      * get all of the bundle items of a set
      */
    public function getSetItems(count:Int, size:String):Array<BundleItem> {
        var ss = sizeDimensions( size );
        return filter(function(i : BundleItem) {
            return i.getDimensions().equals( ss );
        });
    }

    /**
      * get all items at the given time
      */
    public function getByTime(time:Float, threshold:Float=0.88):Array<BundleItem> {
        return filter(function(item) {
            var itemTime = item.getTime();
            return if (itemTime != null) itemTime.almostEquals(time, threshold) else false;
        });
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
        return (fnames().iterator()).map( getItemId );
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
        return (Fs.readDirectory( path ).filter.fn(isBundleItemName( _ )));
    }

    /**
      * check that the given filename appears to be that of a bundle-item
      */
    public inline function isBundleItemName(filename: String):Bool {
        return !(
            (filename.endsWith('.json'))
        );
    }

    /**
      * get subpath of [this]
      */
    public function subpath(s : String):Path {
        return path.plusString( s );
    }

    /**
      * check for existance of a file named [n] in the [path] directory
      */
    public function fexists(n : String):Bool {
        return Fs.exists(subpath( n ));
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
    public function sizeDimensionsRectangle(s : String):Rectangle {
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
    private function sizeDimensions(s : String):Dimensions {
        var r = sizeDimensionsRectangle( s );
        return new Dimensions(floor(r.w), floor(r.h));
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
    private inline function strDimension(d : Dimensions):String {
        return d.toString();
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
    public inline function getItemId(name : String):BundleItem {
        return new BundleItem(this, name);
    }

    /**
      * create a filename string from the given 'item id'
      */
    public inline function getNameForId(id : BundleItem):String {
        return id.name;
    }

    /**
      * get the Path to the bundle_info.json file
      */
    public function info_path():Path {
        return subpath( 'bundle_info.json' );
    }

    /**
      * parse and return the data from bundle_info.json
      */
    public function get_info():Obj {
        var path = info_path();
        if (Fs.exists( path )) {
            return Json.parse(Fs.read( path ).toString());
        }
        else {
            var data = {
                default_thumb_time: 0.0,
                thumb_times: []
            };
            data.default_thumb_time = _defaultThumbTime();
            data.thumb_times = _defaultThumbTimes();
            return Obj.fromDynamic( data );
        }
    }

    /**
      * encode [info] and write it to bundle_info.json
      */
    public function set_info(info : Obj):Void {
        var path = info_path();
        var data = Json.stringify(info.toDyn(), null, '  ');
        Fs.write(path, data);
    }

    /**
      * get/set [info]
      */
    public function info(?newinfo : Obj):Obj {
        if (newinfo == null) {
            return get_info();
        }
        else {
            set_info( newinfo );
            return newinfo;
        }
    }

    /**
      * read, manipulate, write [info]
      */
    public function edit_info(edit:Obj->Void):Void {
        var data = info();
        edit( data );
        info( data );
    }

    /**
      * set the 'default_thumb_time' property
      */
    public function setThumbTime(time : Float):Void {
        edit_info(function(i) {
            i['default_thumb_time'] = time;
        });
    }

    /**
      * get/set the 'thumb_times' property
      */
    public function thumb_times(?value:Array<Float>, sort:Bool=true):Array<Float> {
        if (value == null) {
            return info()['thumb_times'];
        }
        else {
            edit_info(function(i) {
                if ( sort ) {
                    value.sort( Reflect.compare );
                }

                i['thumb_times'] = value;
            });
            return value;
        }
    }

    /**
      * calculate the default thumb time
      */
    private function _defaultThumbTime():Float {
        var allsnaps = getAllSnapshots();
        if (allsnaps.length > 0) {
            var snap : BundleItem;
            if (allsnaps.length == 1) {
                snap = allsnaps[0];
            }
            else {
                snap = RandomTools.choice( allsnaps );
            }
            var time = snap.getTime();
            if (time != null) {
                return time;
            }
        }
        if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
            return (new Random().randfloat(0.0, track.data.meta.duration));
        }
        else {
            return 0.0;
        }
    }

    /**
      * calculate default thumb_times value
      */
    private function _defaultThumbTimes():Array<Float> {
        if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
            var duration:Float = track.data.meta.duration;
            var count:Int = 20;
            var increment:Float = (duration / (count + 0.0));
            var times:Array<Float> = [for (i in 0...count) (increment * i)];
            return times;
        }
        else {
            return new Array();
        }
    }

    /**
      * get the default single-thumbnail in the given size
      */
    public function getSingleThumbnail(size:String='100%'):Promise<BundleItem> {
        return Promise.create({
            track.getData(function(?error, ?dat) {
                if (error != null) {
                    throw error;
                }
                else if (dat != null) {
                    var bundleInfo = info();
                    var thumbTime:Float = bundleInfo.mget('default_thumb_time').or( 0 );
                    var snapp = getSnapshot(thumbTime, size);
                    @forward snapp;
                }
                else {
                    throw 'Error: No data fetched';
                }
            });
        });
    }

    /**
      * get list of thumbnails as defined in bundle_info.json
      */
    public function getThumbnails(size:String='15%', ?slice:{pos:Int, ?end:Int}):ArrayPromise<BundleItem> {
        return Promise.create({
            track.getData(function(?error, ?dat) {
                if (error != null) {
                    throw error;
                }
                else if (dat != null) {
                    var times = thumb_times();
                    if (slice != null)
                        times = times.slice(slice.pos, slice.end);
                    var snaps = getMultipleSnapshots(times, size);
                    @forward snaps;
                }
                else {
                    throw 'Error: No data fetched';
                }
            });
        }).array();
    }

    @:keep
    public function betty() {
        //
    }

/* === Static Methods === */

    /**
      * parse BundleItemType from [s]
      */
    public static function getBundleItemType(s : String):BundleItemType {
        var orig_s:String = s;
        // thumbnail
        if (s.startsWith('t')) {
            s = s.slice( 1 );
            return Thumbnail(basicSizeDimensions(s.beforeLast('.png')));
        }
        // snapshot
        else if (s.startsWith('s')) {
            s = s.slice( 1 ).beforeLast('.png');
            var a = s.separate('@');
            return Snapshot(Std.parseFloat(a.after), basicSizeDimensions(a.before));
        }
        // anything else
        else {
            throw new js.Error('Could not resolve BundleItemType from "$orig_s"');
        }
    }

    public static function basicSizeDimensions(size : String):Dimensions {
        return size.split('x').with([w, h], new Dimensions(Std.parseInt(w), Std.parseInt(h)));
    }

/* === Instance Fields === */

    public var track : Track;
    public var title : String;
    public var path : Path;

    private var _ic : Map<String, Image>;

    // thumb-generation event emitter
    private var tgee : EventDispatcher;
    private var _watcher : Maybe<tannus.node.Fs.FSWatcher> = null;
}
