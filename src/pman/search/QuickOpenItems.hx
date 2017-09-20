package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.db.AppDir;
import pman.search.QuickOpenItem;
import pman.media.MediaSource;

import electron.ext.App;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda; 
using pman.media.MediaTools;

@:expose( 'qoi' )
class QuickOpenItems {
    /**
      * asynchronously fetch all available QuickOpenItems
      */
    public static function get(f : Array<QuickOpenItem>->Void):Void {
        var results:Array<QuickOpenItem> = new Array();
        var stack = new AsyncStack();
        var ad = new AppDir();
        inline function d(f) stack.push( f );
        inline function qoi(item) results.push( item );

        d(function(next) {
            defer(function() {
                var spln = ad.allSavedPlaylistNames();
                for (name in spln) {
                    qoi(QOPlaylist( name ));
                }
                next();
            });
        });

        d(function(next) {
            ad.getMediaSources(function(?error, ?mspaths) {
                var msdirs = mspaths.map.fn(new Directory( _ ));
                msdirs.igetAllOpenableFiles(function( files ) {
                    for (file in files) {
                        //qoi(QOFile( file ));
                        qoi(QOMedia(MSLocalPath( file.path )));
                    }
                    next();
                });
            });
        });

        stack.run(function() {
            f( results );
        });
    }
}
