package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.math.*;
import tannus.sys.Path;
import tannus.TSys as Sys;

import pman.core.*;
import pman.media.*;
import pman.async.tasks.*;
import pman.bg.media.*;
import pman.bg.media.Mark;

import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.PathTools;
using pman.media.MediaTools;

class MediaCommand extends HierCommand {
    override function _build_() {
        inline function cmd(cmd:HierCommand, name, main) {
            return cmd.subCmd(name, onlyArgs(main));
        }
        function pcmd(self:HierCommand, name, f) {
            self.createSubCommand(name, {}, function(c) {
                c.pythonicMain( f );
            });
        }

        cmd(this, 'favorite, star', cmdFavorite);
        cmd(this, 'unfavorite, unstar', cmdUnfavorite);
        cmd(this, 'rename, mv', cmdRename);
        cmd(this, 'editinfo, edit-info', cmdEditInfo);

        createSubCommand('add', null, function(add) {
            cmd(add, 'star, actor, actress, pornstar', cmdAddActor);
            cmd(add, 'tag, category', cmdAddTag);
            pcmd(add, 'bookmark, mark', cmdAddBookmark);
        });

        createSubCommand('remove,rm,delete,del', {main: onlyArgs(cmdDeleteMedia)}, function(del) {
            //TODO
            //cmd(del, 'star, actor, actress, pornstar', cmdDeleteActor);
            cmd(del, 'tag, category', cmdDeleteTag);
        });
    }

    override function main(i, argv, done:VoidCb) {
        trace('no arguments provided');
    }

    /**
      command to add a bookmark to the media
     **/
    function cmdAddBookmark(args:Array<CmdArg>, kwargs:Map<String, Dynamic>, done:VoidCb) {
        if (args.empty()) {
            player.addBookmark( done );
        }
        else {
            var title:String = argumentString(args[0]);
            var type:Int = 0;
            if (kwargs.exists('type')) {
                switch (Std.string(kwargs['type'])) {
                    case 'normal', 'named', 'default', '':
                        type = 0;

                    case 'scene', 'clip':
                        type = 1;

                    case _:
                        type = 0;
                }
            }

            var time:Float = player.currentTime;
            if (kwargs.exists('time')) {
                time = Std.parseFloat('' + kwargs['time']);
            }

            steppedTrackbatch(done, function(track, add, exec) {
                add(function(next) {
                    track.data.addMark(new Mark((switch type {
                        case 0: Named(title);
                        case 1: Scene((kwargs.exists('end') ? SceneEnd : SceneBegin), title);
                        case _: Named(title);
                    }), time));
                });
                
                add(cast track.data.save.bind(_, database));

                exec();
            }, ['marks']);
        }
    }

    /**
      'main' method for the 'add actor [x]' command
     **/
    function cmdAddActor(args:Array<CmdArg>, done:VoidCb) {
        function parseName(a: Array<CmdArg>):Array<String> {
            return _argnames_(a, (parts -> parts.map.fn(_.capitalize()).join(' ')));
        }

        cmdAdder(args, done, parseName, function(track, names, next) {
            for (name in names) {
                track.data.addActor( name );
            }

            track.data.save(next, null);
        },
        ['actors']);
    }

    /**
      command to add one or more tags to media
     **/
    function cmdAddTag(args:Array<CmdArg>, done:VoidCb) {
        /* parse the argument-list into tag-names */
        function parse(a: Array<CmdArg>):Array<String> {
            return _argnames_(a, (parts -> parts.join(' ').toLowerCase()));
        }

        cmdAdder(args, done, parse, function(track, tags, next) {
            for (tag in tags) {
                track.data.addTag( tag );
            }

            track.data.save(next, null);
        }, ['tags']);
    }

    function cmdDeleteTag(args:Array<CmdArg>, done:VoidCb) {
        /* parse the argument-list into tag-names */
        function parse(a: Array<CmdArg>):Array<String> {
            return _argnames_(a, (parts -> parts.join(' ').toLowerCase()));
        }

        cmdAdder(args, done, parse, function(track, tags, next) {
            for (tag in track.data.tags) {
                if (tags.has(tag.name)) {
                    track.data.removeTag( tag );
                }
            }

            track.data.save(next, null);
        }, ['tags']);
    }

    /**
      utility method
     **/
    function cmdAdder<T>(argv:Array<CmdArg>, done:VoidCb, parse:Array<CmdArg>->T, apply:Track->T->VoidCb->Void, ?attrs:Array<String>, ?ensureHasData:Bool=true):Void {
        var data:T = parse( argv );
        steppedTrackbatch(done, function(track, add, exec) {
            add(apply.bind(track, data, _));
            exec();
        },
        attrs, ensureHasData);
    }

    function steppedTrackbatch(done:VoidCb, body:Track->(VoidAsync->Void)->VoidCb->Void, ?trackProperties:Array<String>, ensureHasData:Bool=true):Void {
        trackbatch(done, function(track, next) {
            vsequence(function(step, run) {
                if ( ensureHasData ) {
                    step(_pva(track.getData.bind(null)));
                }

                if (trackProperties != null) {
                    step(_pva(track.data.ensureHasProperties.bind(trackProperties, null)));
                }

                body(track, step, run);
            }, next);
        });
    }

    function cmdSetStarredAll(value:Bool, done:VoidCb) {
        _pw(tracks(), done, function(tracks: Array<Track>) {
            vbatch(function(add, run) {
                for (t in tracks) {
                    add(t.setStarred.bind(value, _));
                }
                run();
            }, done);
        });
    }

    function cmdFavorite(args, done:VoidCb) {
        cmdSetStarredAll(true, done);
    }

    function cmdUnfavorite(args, done:VoidCb) {
        cmdSetStarredAll(false, done);
    }

    function cmdEditInfo(args, done:VoidCb) {
        if (player.track == null)
            done();
        else
            @:privateAccess player.track._edit();
    }

    function cmdDeleteMedia(args, done:VoidCb) {
        steppedTrackbatch(done, function(track, add, exec) {
            var task = new TrackDelete(track, database.mediaStore);
            add(cast task.run.bind(_));
            exec();
        });
    }

    /**
      rename the underlying file for media
     **/
    function cmdRename(args:Array<CmdArg>, done:VoidCb):Void {
        if (!args.empty()) {
            var curPath = player.track.getFsPath();
            var newName:String = ('' + args.shift().value);
            var newPath:Path = (curPath.directory.plusString( newName )).normalize();
            _renameTrack(newPath, done);
        }
        else {
            _renameTrack(null, done);
        }
    }

    function _renameTrack(newPath:Null<Path>, done:VoidCb):Void {
        var task = new TrackRename(player.track, database.media, newPath);
        task.run( done );
    }

    static inline function _pw<T, P:Promise<T>>(promise:P, callback:VoidCb, f:T->Void) {
        return promise.then(f, callback.raise());
    }

    static inline function _pva<P:Promise<Dynamic>>(promise:Void->P):VoidAsync {
        return (function(callback: VoidCb):Void {
            promise().void().toAsync( callback );
        });
    }

    inline function _argnames_<T>(args:Array<CmdArg>, map:Array<String>->T):Array<T> {
        return args.map(argumentString).map(_names_).flatten().map.fn(_.chunk()).map(map);
    }
    
    inline function _reduceargnames_<Item,Out>(args:Array<CmdArg>, itemize:Array<String>->Item, f:(acc:Out, item:Item)->Out, acc:Out):Out {
        return _argnames_(args, itemize).reduce(f, acc);
    }

    function tracks():Promise<Array<Track>> {
        if (ids.empty() && uris.empty()) {
            return cast Promise.resolve([player.track]);
        }
        else {
            return new Promise(function(accept, reject) {
                var kwa = ids.concat(uris);
                database.mediaStore.getRowsByKeys( kwa ).then(function(rows) {
                    accept(untyped Promise.all(rows.map(row -> Track.fromRow(row))));
                }, reject);
            });
        }
    }

    function trackbatch(done:VoidCb, body:(track:Track, next:VoidCb)->Void) {
        _pw(tracks(), done, function(tracks: Array<Track>) {
            vbatch(function(addSet, execAll) {
                for (track in tracks) {
                    addSet(function(next) {
                       body(track, next); 
                    });
                }
                execAll();
            },
            done);
        });
    }

/* === Instance Fields === */

    var ids: Array<String> = {[];};
    var uris: Array<String> = {[];};
}

