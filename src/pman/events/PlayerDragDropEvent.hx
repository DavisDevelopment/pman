package pman.events;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.html.fs.WebFile;

import js.html.DragEvent as NativeDragEvent;
import js.jquery.Event as JqEvent;

import pman.ds.*;
import pman.media.Track;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

@:allow( pman.ui.DragDropManager )
class PlayerDragDropEvent extends DragDropEvent {
    public function new(event:DragDropEvent, ?tracks:Array<Track>):Void {
        super( event.e );

        this.tracks = tracks;

        //onDefaultPrevented.clear();
        //onPropogationStopped.clear();
        //onCancelled.clear();
    }

    public function playerPanePosition():Point<Float> {
        return player.view.stage.globalToLocal(globalPosition());
    }

    public var tracks : Maybe<Array<Track>>;
}
