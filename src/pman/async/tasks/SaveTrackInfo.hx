package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.async.*;
import pman.media.info.*;
import pman.Globals.*;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class SaveTrackInfo extends Task1 {
    /* Constructor Function */
    public function new(track:Track, delta:TrackInfoFormValueDelta):Void {
        super();

        this.track = track;
        this.delta = delta;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : VoidCb):Void {
        [rename_track, edit_data].series( done );
    }

    /**
      * rename the Track, if necessary
      */
    private function rename_track(done : VoidCb):Void {
        if (delta.title != null) {
            var newPath:Path = (track.getFsPath().directory.plusString( delta.title.current )).normalize();
            var renamer = new TrackRename(track, database.mediaStore, newPath);
            renamer.run( done );
        }
        else {
            done();
        }
    }

    /**
      * do the stuff
      */
    private function edit_data(done : VoidCb):Void {
        track.editData(function(data, next) {
            // create list to hold sub-tasks
            var steps:Array<VoidAsync> = new Array();

            // handle synchronous changes
            steps.push(function(end) {
                if (delta.channel != null)
                    data.channel = delta.channel.current;

                if (delta.contentRating != null)
                    data.contentRating = delta.contentRating.current;

                if (delta.rating != null)
                    data.rating = delta.rating.current;

                if (delta.description != null)
                    data.description = delta.description.current;

                end();
            });

            // handle tags
            steps.push(function(end) {
                if (delta.tags != null) {
                    var newTags = delta.tags.current;
                    data.tags = new Array();
                    for (t in newTags) {
                        data.addTag( t );
                    }
                }
                end();
            });

            // handle Actors
            steps.push(function(end) {
                if (delta.actors != null) {
                    if (delta.actors.current != null) {
                        var newActors = delta.actors.current;
                        data.writeActors(newActors, function(?error, ?al) {
                            end( error );
                        });
                    }
                    else {
                        end();
                    }
                }
                else {
                    end();
                }
            });

            // run those sub-tasks
            steps.series( next );

        }, function(?error) {
            done( error );
        });
    }

/* === Instance Fields === */

    public var track : Track;
    public var delta : TrackInfoFormValueDelta;
}

typedef TrackInfoFormValueDelta = {
    ?title: Delta<String>,
    ?description: Delta<String>,
    ?tags: Delta<Array<String>>,
    ?actors: Delta<Array<String>>,
    ?rating: Delta<Float>,
    ?contentRating: Delta<String>,
    ?channel: Delta<String>
};
