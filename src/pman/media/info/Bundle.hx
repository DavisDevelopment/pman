package pman.media.info;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;
import tannus.geom.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.math.Time;
import tannus.math.Random;
import tannus.media.Duration;
import tannus.async.*;
import tannus.stream.StreamInput;
import tannus.async.promises.*;

import gryffin.display.Image;

import pman.async.tasks.*;
import pman.media.info.BundleItemType;
import pman.bg.media.Dimensions;
import pman.format.time.TimeExpr;
import pman.format.time.TimeParser;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType as Either;

import tannus.math.TMath.*;
import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using tannus.ds.IteratorTools;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;

/**
  represents a folder in which asset files associated with [track]'s media are stored
 **/
class Bundle {
    /* Constructor Function */
    public function new(track : Track):Void {
        this.track = track;
        this.title = track.title;
        this.path = Bundles.assertBundlePath( title );

        _ic = new Map();
        tgee = new EventDispatcher();
        @:privateAccess {
            tgee.__checkEvents = false;
        }
    }

/* === Instance Methods === */

    /**
      get a snapshot item, and optionally create it if necessary
     **/
    public function getSnapshot(time:Float, ?size:String):Promise<BundleItem> {
        /* default size to 100% */
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
      get a list of snapshots
     **/
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
      create and return a readable-stream of BundleItem instances corresponding with the [times] provided
     **/
    public function streamMultipleSnapshots(times:Array<Float>, ?size:String):StreamInput<BundleItem> {
        if (size == null) {
            size = '10%';
        }

        // parse actual dimensions from [size]
        var dim = sizeDimensions( size );
        // create variable to hold BundleItem results
        var items:Array<BundleItem> = new Array();

        var iw:StreamInputPusher<BundleItem> = null;

        inline function add(i: BundleItem):Bool {
            return iw.next( i );
        }

        inline function flush() {
            var keepReading: Bool = true;
            if (iw != null && items.hasContent()) {
                do {
                    keepReading = iw.next(items.shift());
                }
                while (keepReading && !items.empty());
            } 

            return keepReading;
        }

        function onAllBuffered() {
            null;
        }

        var _status = [
            false, // $0 initialization complete
            false, // $1 pre-existing items buffered
            false, // $2 generator task started
            false, // $3 newly-created items buffered
            false, // $4 all items buffered
            false
        ];

        inline function status(i:Int, ?v:Bool):Bool {
            return (v != null ? _status[i] = v : _status[i]);
        }


        function _init(o, done:VoidCb) {
            iw = o;

            //status(0, true);
            var missing = [];

            for (time in times) {
                var pess = findSnapshot(time, size);
                if (pess != null) {
                    add( pess );
                }
                else {
                    missing.push( time );
                }
            }
            status(1, true);

            vsequence(
                function(task, exec) {
                    task(function(next) {
                        var gen = new GenerateBundleSnapshots(track, missing, size);
                        var bnpp = (gen.run.toPromise().array());
                        status(2, true);
                        bnpp.then(function(paths) {
                            if (paths != null) {
                                var item:BundleItem;
                                for (path in paths) {
                                    item = new BundleItem(this, path.name);
                                    add( item );
                                }
                                status(3, true);
                                defer(function() {
                                    next();
                                });
                            }
                            else {
                                next('Expected Array<tannus.sys.Path>, got null');
                            }
                        }, next.raise());
                    });

                    defer(function() {
                        exec();
                    });
                },
                function(?error) {
                    if (error != null) {
                        //o.error( error );
                        done( error );
                    }
                    else {
                        status(4, true);
                        //done();
                    }
                }
            );
            status(0, true);
            done();
        }

        /**
          'read' method for the returned stream
         **/
        function _read(o, len) {
            if (status(0)) {
                switch (_status.slice(1, 3)) {
                    // all items buffered
                    case [true, true, true]:
                        o.done();

                    case [true, _, false]:
                        // do nothing, 'readable' will be dispatched when more items are buffered

                    case other:
                        //
                }
            }
        }

        var input = new StreamInput({
            init: _init,
            read: _read
        });
        input.pause();

        return input;
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
      * watch [this] Bundle for changes made to its contents
      */
    public function watch(handler : BundleItem->Void):Void {
        tgee.on('change', handler);

        if (_watcher == null) {
            _watcher = tannus.node.Fs.watch(path, function(type, filename) {
                //trace( filename );
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
      get the Path to the bundle_info file
     **/
    public inline function info_path():Path {
        return subpath( 'bundle_info.json' );
    }

    /**
      * parse and return the data from bundle_info.json
      */
    public function get_info():BundleInfoFileData {
        var path = info_path();
        if (Fs.exists( path )) {
            try {
                var data:BundleInfoFileData = cast Json.parse(Fs.read( path ).toString());
                if (Reflect.hasField(data, 'default_thumb_time')) {
                    data.defaultThumbTime = Reflect.field(data, 'default_thumb_time');
                    Reflect.deleteField(data, 'thumb_times');
                }
                if (Reflect.hasField(data, 'thumbTimes')) {
                    data.thumbTimes = Reflect.field(data, 'thumb_times');
                    Reflect.deleteField(data, 'thumb_times');
                }
                return data;                
            }
            catch (e: Dynamic) {
                Fs.deleteFile( path );
                return get_info();
            }
        }
        else {
            var data:BundleInfoFileData = {
                defaultThumbTime: _defaultThumbTime(),
                thumbTimes: _defaultThumbTimes()
            };
            //data.default_thumb_time = _defaultThumbTime();
            //data.thumb_times = _defaultThumbTimes();
            //return Obj.fromDynamic( data );
            return data;
        }
    }

    /**
      * encode [info] and write it to bundle_info.json
      */
    public function set_info(info : BundleInfoFileData):BundleInfoFileData {
        //var path:Path = info_path();
        //var data:String = Json.stringify( info );
        //Fs.write(path, data);
        Fs.write(info_path(), Json.stringify(info));
        return info;
    }

    /**
      * read, manipulate, write [info]
      */
    public function edit_info(edit: BundleInfoFileData->Void):Void {
        var data:BundleInfoFileData = get_info();
        edit( data );
        set_info( data );
    }

    /**
      set the time at which the thumbnail should be generated
     **/
    public function setThumbTime(time: Float):Void {
        edit_info(function(i) {
            i.defaultThumbTime = time;
        });
    }

    /**
      get/set the list of timestamps that thumbnails should be generated for
     **/
    public function thumb_times(?value:Array<Float>, sort:Bool=true):Array<Float> {
        if (value == null) {
            return get_info().thumbTimes;
        }
        else {
            edit_info(function(i) {
                if ( sort ) {
                    value.sort( Reflect.compare );
                }

                i.thumbTimes = value;
            });
            return value;
        }
    }

    /**
      * calculate the default thumb time
      */
    private function _defaultThumbTime():Float {
        // create pseudo-random number generator
        var rand:Random = new Random();

        // get all snapshots
        var allsnaps = getAllSnapshots();

        // if [allsnaps] not empty
        if (allsnaps.length > 0) {
            var snap:BundleItem = (allsnaps.length == 1) ? allsnaps[0] : rand.choice(allsnaps);
            var time = snap.getTime();
            if (time != null) {
                return time;
            }
        }

        if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
            return (rand.randfloat(0.0, track.data.meta.duration));
        }
        else {
            return -1.0;
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
                    var bundleInfo = get_info();
                    var thumbTime:Float = bundleInfo.defaultThumbTime;
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

    /**
      create and return a Stream of thumbnails
     **/
    @:keep
    public function readThumbnails(size:String='15%', ?slice:{pos:Int, ?end:Int}):StreamInput<BundleItem> {
        var times = thumb_times();
        if (slice != null) {
            times = times.slice(slice.pos, slice.end);
        }

        var ssi;
        var input = new StreamInput({
            init: function(o, done) {
                ssi = streamMultipleSnapshots(times, size);
                ssi.pause();
                ssi.onEnd(function() {
                    //o.done();
                });
                ssi.onError(function(error) {
                    o.error( error );
                });
            },
            read: function(o, len) {
                o.next(ssi.read(len));
            }
        });
        input.pause();
        return input;
    }

    /**
      test the stream interface
     **/
    @:keep
    public function betty(?times:Iterable<TimeVal>, ?size:String):Void {
        var _times: Array<Time>;
        if (times != null) {
            _times = times.array().map( resolveTime );
        }
        else {
            _times = this.getAllSnapshots()
                //.map(item -> item.getTime().toNonNullable())
                .map.fn(_.getTime().toNonNullable())
                .compact()
                .map.fn(Time.fromFloat(_));
        }

        var tns = streamMultipleSnapshots(_times.map.fn(_.toFloat()), size);
        tns.onReadable(function() {
            trace("Stream is readable");
            var tn:BundleItem;
            do {
                tn = tns.read(1);
                trace( tn );
            }
            while (tn != null);
        });
        tns.onEnd(function() {
            trace("Stream ended");
        });
        tns.onError(function(error) {
            throw error;
        });
        tns.onClose(function(?error) {
            trace('Stream closed ${error!=null?"with error:"+error:"without errors"}');
        });
        tns.onData(function(item) {
            trace( item );
        });
        echo( tns );
    }

    /**
      allow time-offsets to be provided in many different formats
      all of which are resolved back to a Time instance by this method
     **/
    private function resolveTime<T:TimeVal>(t: T):Time {
        var tv:TimeValue = TimeValue.fromAny( t );
        if (tv.isAbsolute(true)) {
            return tv.getTime();
        }
        else {
            if (track.data != null && track.data.meta != null && track.data.meta.duration != null) {
                return new Time(tv.getSecondsWith( track.data.meta.duration ));
            }
            else {
                throw 'Cannot resolve relative/proportional time expressions until metadata is loaded';
            }
        }
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
        return size.split('x')
            .with([w, h], new Dimensions(Std.parseInt(w), Std.parseInt(h)));
    }

/* === Computed Instance Fields === */

    //public var info(get, set): BundleInfoFileData;

/* === Instance Fields === */

    public var track : Track;
    public var title : String;
    public var path : Path;

    private var _ic : Map<String, Image>;

    // thumb-generation event emitter
    private var tgee : EventDispatcher;

    // file-watcher object
    private var _watcher : Maybe<tannus.node.Fs.FSWatcher> = null;
}

/**
  type of object stored in the bundle_info.json file
 **/
typedef BundleInfoFileData = {
    var defaultThumbTime: Null<Float>;
    var thumbTimes: Array<Float>;
};

abstract TimeValue (TimeValueType) from TimeValueType to TimeValueType {

    public var type(get, never): TimeValueType;
    private inline function get_type() return this;

    public function isAbsolute(noop: Bool=false):Bool {
        return noop ? type.match(TvTTime(_, null)) : type.match(TvTTime(_, _));
    }

    public inline function getSeconds():Float {
        return switch type {
            case TvTTime(secs, _): secs;
            default: throw 'TypeError: Cannot extract seconds from $type';
        };
    }

    public inline function getTime():Time {
        return new Time(getSeconds());
    }

    public function getSecondsWith(base_seconds: Float):Float {
        switch type {
            case TvTTime(secs, null):
                return secs;
            case TvTTime(secs, op):
                secs = (switch op {
                    case Plus: abs(secs);
                    case Minus: -abs(secs);
                    case _: throw 'Wtf($type)';
                });
                return (base_seconds + secs);
            case TvTPercent(perc, null):
                return perc.of( base_seconds );
            case TvTPercent(perc, op):
                var secs:Float = perc.of( base_seconds );
                secs = (switch op {
                    case Plus: abs(secs);
                    case Minus: -abs(secs);
                    case _: throw 'Wtf($type)';
                });
                return (base_seconds + secs);
            case _:
                throw 'Wtf($type)';
        }
    }

    public function getTimeWith(base: Time):Time {
        return new Time(getSecondsWith(base.toFloat()));
    }

    @:from
    public static function fromAny<T:TimeVal>(v: T):TimeValue {
        return typeFromAny( v );
    }

    public static function typeFromAny<T:TimeVal>(value: T):TimeValueType {
        if ((value is Float)) {
            return TvTTime((value : Float));
        }
        else if ((value is Time)) {
            return TvTTime((value : Time).toFloat());
        }
        else if ((value is Duration)) {
            return TvTTime((value : Duration).toFloat());
        }
        else if ((value is String)) {
            var sval:String = cast value;
            var expr = TimeParser.run( sval );
            switch expr {
                case null:
                    throw 'Unable to parse a Time value from "$sval"';

                case ETime(time):
                    return TvTTime(time.toFloat());

                case ERel(op, ETime(_.toFloat()=>time)):
                    return TvTTime(time, op);

                case EPercent( percent ):
                    return TvTPercent( percent );

                case ERel(op, EPercent(percent)):
                    return TvTPercent(percent, op);

                case _:
                    throw 'Unable to parse a Time value from $expr';
            }
        }
        return null;
    }
}

enum TimeValueType {
    TvTTime(seconds:Float, ?rel:TimeOp);
    TvTPercent(percent:Percent, ?rel:TimeOp);
}

typedef TimeVal = Either<Either<String, Float>, Either<Time, Duration>>;

