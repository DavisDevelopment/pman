package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.node.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

//import pman.async.AlbumArtLoader;
import pman.async.tasks.LoadAlbumArt;
import pman.core.*;
import pman.media.*;
import pman.tools.mediatags.MediaTagReader;
import pman.ui.*;
import pman.edb.*;

import js.Browser.window;
import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * class used for rendering the view associated with audio media being played to the local device
  */
class LocalAudioRenderer extends LocalMediaObjectRenderer<Audio> {
	/* Constructor Function */
	public function new(m:Media, mc:MediaController):Void {
		super(m, mc);
	}

/* === Instance Methods === */

    /**
      * render shit
      */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);
        if (visualizer != null) {
            visualizer.render(stage, c);
        }
    }

    /**
      * update shit
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        if (prefs.directRender && underlay != null) {
            var imgSize:Rect<Float> = new Rect(0.0, 0.0, albumArt.width, albumArt.height);
            var viewport:Rect<Float> = pv.rect.clone();
            var scale:Float = marScale(imgSize, viewport);
            var aar:Rect<Float> = new Rect();
            
            aar.w = (imgSize.w * scale);
            aar.h = (imgSize.h * scale);
            aar.centerX = viewport.centerX;
            aar.centerY = viewport.centerY;
            
            underlay.setRect( aar );
        }
        if (visualizer != null) {
            visualizer.update( stage );
        }
    }

    /**
      * 
      */
	private inline function marScale(src:Rect<Float>, dest:Rect<Float>):Float {
		return min((dest.width / src.width), (dest.height / src.height));
	}

    /**
      * when [this] gets attached
      */
    override function onAttached(pv : PlayerView):Void {
        this.pv = pv;

        // create and attach a visualizer
        var av:AudioVisualizer = (switch ( database.configInfo.visualizer ) {
            case 'spectograph':
                cast new SpectographVisualizer(cast this);

            case 'bars':
                cast new BarsVisualizer(cast this);

            default:
                cast new BarsVisualizer(cast this);
        });
        attachVisualizer(av, function() {
            visualizer.player = pv.player;
        });
        defer(function() {
            _maybe_load_albumart( pv.player.track );
        });
    }

    /**
      * when [this] gets detached
      */
    override function onDetached(pv : PlayerView):Void {
        detachVisualizer(function() {
            if (underlay != null) {
                underlay.destroy();
            }
        });
    }

    // set up event listeners that may lead to getting album art
    private function _maybe_load_albumart(t : Track):Void {
        if ( !prefs.showAlbumArt ) {
            return ;
        }

        function _load_albumart():Void {
            if (visualizer == null) {
                return ;
            } 
            else {
                /*
                var artLoader = new AlbumArtLoader();
                var artPromise = artLoader.loadAlbumArt( t );
                artPromise.then(function(art : Null<Image>) {
                    albumArt = art;
                    if ( prefs.directRender ) {
                        underlay = new AlbumArtUnderlay( albumArt );
                        underlay.appendTo('body');
                    }
                });
                */
                var artProm = LoadAlbumArt.loadAlbumArt(t.getFsPath() + '');
                artProm.then(function(art: Null<Image>) {
                    albumArt = art;
                    if ( prefs.directRender ) {
                        underlay = new AlbumArtUnderlay( albumArt );
                        underlay.appendTo('body');
                    }
                });
                artProm.unless(function(error: Dynamic) {
                    throw error;
                });
            }
        }

        //window.setTimeout(_load_albumart, 2000);
        wait(2000, _load_albumart);
    }

    public var prefs(get, never):Preferences;
    private inline function get_prefs() return BPlayerMain.instance.db.preferences;

/* === Instance Fields === */

	private var pv : Null<PlayerView> = null;
	
	public var albumArt : Null<Image> = null;
	public var underlay : Null<AlbumArtUnderlay> = null;
}
