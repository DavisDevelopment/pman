package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.geom2.*;
import tannus.TSys.systemName;

import electron.Shell;
import electron.ext.App;
import electron.ext.ExtApp;

import pman.core.*;
import pman.media.*;
import pman.media.info.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;

import ffmpeg.Fluent;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class ScaleBundleItem extends ResizeImageFile {
    /* Constructor Function */
    public function new(item:BundleItem, sizer:Area<Int>->Area<Int>):Void {
        super(item.getPath(), 'place/hold.er', new Area(0, 0));

        srcItem = item;
        var srcdim:Dimensions = item.getDimensions();
        size = sizer(srcdim.toArea());
        
        opath = item.bundle.getPathToSnapshot(item.getTime(), ('${size.width}x${size.height}'));
    }

/* === Instance Methods === */

    /**
      * bleh
      */
    public function go(done : Cb<BundleItem>):Void {
        run(function(?err, ?path) {
            if (err != null) {
                return done(err, null);
            }
            else {
                var oitem = new BundleItem(srcItem.bundle, path.name);
                done(null, oitem);
            }
        });
    }

    /**
      * get it to save the images properly
      */
    override function beforeOperation(m : Fluent):Void {
        //m.size('${targetSize.width}:${targetSize.height}');
    }

    private var srcItem:BundleItem;
}
