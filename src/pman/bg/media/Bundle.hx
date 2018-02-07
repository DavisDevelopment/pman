package pman.bg.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.http.Url;

import pman.bg.db.*;
import pman.bg.tasks.*;
import pman.bg.media.MediaSource;
import pman.bg.media.MediaType;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.MediaTools;
using tannus.async.Asyncs;

class Bundle {
    /* Constructor Function */
    public function new(type: BundleType):Void {
        this.type = type;

        this._rs = new OnceSignal();
    }

/* === Instance Methods === */

    /**
      * initialize [this] Bundle
      */
    public function init(?done: VoidCb):Void {
        if (done == null)
            done = VoidCb.noop();
        done = done.wrap(function(prev, ?error) {
            if (!isReady() && error == null) {
                announceReady();
            }
            prev( error );
        });

        if (isReady()) {
            return done();
        }
        else {
            switch ( type ) {
                case BTMediaFile( m ):
                    if (m.media != null) {
                        return done();
                    }

                    var db = new Database();
                    db.init(function(?error) {
                        if (error != null) {
                            done( error );
                        }
                        else {
                            db.media.getRowById(m.mediaId, function(?error, ?mediaRow) {
                                if (error != null) {
                                    done( error );
                                }
                                else if (mediaRow != null) {
                                    Media.fromRow(mediaRow, function(?error, ?media:Media) {
                                        if (error != null) {
                                            done( error );
                                        }
                                        else if (media != null) {
                                            m.media = media;
                                            done();
                                        }
                                        else {
                                            done('Error: Unable to obtain media information');
                                        }
                                    });
                                }
                                else {
                                    done('Error: Unable to obtain media information');
                                }
                            });
                        }
                    });
            }
        }
    }

    public inline function isReady():Bool return _rs.isReady();
    public inline function onReady(f: Void->Void):Void return _rs.on( f );
    private inline function announceReady():Void _rs.announce();

    /*
    public function getBundleName():String {
        switch ( type ) {
            case BTMediaFile( m ):
                var uri = m.media.mediaUri;
                if (uri.isUri()) {
                    switch (uri.toMediaSource()) {
                        case MSLocalPath( path ):
                            //

                        case MS
                    }
                }
        }
    }
    */

/* === Instance Fields === */

    public var type: BundleType;

    private var _rs: OnceSignal;
}

enum BundleType {
    BTMediaFile(data: MediaFileBundleData);
}

typedef MediaFileBundleData = {
    mediaId: String,
    ?media: MediaData
};
