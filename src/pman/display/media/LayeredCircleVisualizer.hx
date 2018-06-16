package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.geom2.Angle;
import tannus.geom2.Arc;
import tannus.geom2.Velocity;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.html.Win;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.ds.FixedLengthArray;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
//import pman.display.media.AudioPipeline;
import pman.display.media.CircleBasedVisualizer;
import pman.display.media.audio.*;
import pman.display.media.AudioVisualizer;
import pman.display.media.audio.AudioPipeline;
import pman.display.media.audio.AudioPipelineNode;
import pman.display.media.CircleBasedVisualizer;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using pman.display.media.AudioVisualizerTools;

class LayeredCircleVisualizer extends CircleBasedVisualizer {
    /* Constructor Function */
    public function new(r) {
        super(r);

        displayType = Circle;
        dataSpec = Trio(Mono(UInt8TimeDomain), Mono(UInt8TimeDomain), Mono(UInt8TimeDomain));
    }

/* === Instance Methods === */

    /**
      * when [this] is attached to the Media
      */
    override function attached(done : VoidCb):Void {
        super.attached(done.wrap(function(_, ?error) {
            _(error);
        }));
    }

    override function initialize(done: VoidCb):Void {
        config({
            fftSize: 2048,
            smoothing: 0.0
        });

        done();
    }

    override function paint(c: Ctx):Void {
        super.paint( c );

        /**
          build the color gradient used for fills
         **/
        if (vdat != null && fill_gradient == null) {
            //TODO create gradient
        }

        if (vdat != null) {
            draw( c );
            //draw_debug( c );
        }
    }

    /**
      draw debug information
     **/
    function draw_debug(c: Ctx):Void {
        //TODO
    }

    /**
      draw visualization
     **/
    private function draw(c: Ctx) {
        if (isCircle()) {
            draw_circle( c );
        }
    }

    /**
      draw the circle display
     **/
    inline function draw_circle(c: Ctx):Void {
        var dat = vdat.toDataPair();

        switch displayArea {
            case Mono( r ):
                var rp = bisect( r );
                draw_circle_type(c, rp.left, dat.left);
                draw_circle_type(c, rp.right, dat.right);

            case Trio(left, middle, right):
                inline function doubleDo(r:Rect<Float>, d:AudioData<Int>) {
                    var rp = bisect(r, true);
                    draw_circle_type(c, rp.left, d);
                    draw_circle_type(c, rp.right, d);
                }

                doubleDo(left, dat.left);
                doubleDo(right, dat.right);

            default:
                trace('Unexpected $displayArea');
        }
    }

    /**
      actually draw the given AudioData
     **/
    inline function draw_circle_type(c:Ctx, rect:Rect<Float>, d:AudioData<Int>, ?mod:DrawMod) {
        c.save();

        var pos = circPos( rect );
        var path = buildCirclePath(d, pos, mod);

        try {
            c.fillStyle = player.theme.secondary;
        }
        catch (e: Dynamic) {
            c.fillStyle = 'peachpuff';
        }
        c.shadowBlur = 7.0;
        c.shadowColor = '#FFF';
        c.fill( path );

        //c.strokeStyle = player.theme.secondary.darken( 18 );
        //c.lineWidth = 1.0;
        //c.stroke( path );

        c.restore();
    }

    /**
      Compute circle position
     **/
    inline function circPos(r: Rect<Float>):CircPos {
        var max = maxRadius( r ), min = (max * 0.65);
        return {
            rect: r,
            center: r.center.clone(),
            maxRadius: max,
            minRadius: min
        };
    }

    inline function maxRadius(r: Rect<Float>):Float {
        return (min(r.width, r.height) / 2);
    }

    static inline function bisect(r:Rect<Float>, vertical:Bool=false):Pair<Rect<Float>, Rect<Float>> {
        var haf = vertical ? (r.height / 2) : (r.width / 2);
        return 
            if ( vertical )
                new Pair(
                    new Rect(r.x, r.y, r.w, haf),
                    new Rect(r.x, haf, r.w, haf)
                )
            else
                new Pair(
                    new Rect(r.x, r.y, haf, r.h),
                    new Rect(haf, r.y, haf, r.h)
                );
    }

    inline function getGradient(c:Ctx, pos:CircPos) {
        var g = c.createRadialGradient(pos.center.x, pos.center.y, 2, pos.center.x, pos.center.y, pos.maxRadius);
        g.addColorStop(0.0, Std.string(lightBlue()));
        g.addColorStop(1.0, Std.string(player.theme.secondary));
        //g.addColorStop(1.0, '#FF0000');
        return g;
    }

    inline function lightBlue():Color {
        if (_lblue == null) {
            _lblue = player.theme.secondary.invert().lighten( 20 );
        }
        return _lblue;
    }

    /**
      build the path for the 'circle' display
     **/
    private function buildCirclePath(d:AudioData<Int>, pos:CircPos, ?mod:DrawMod):Path2D {
        if (mod == null)
            mod = {};

        var path = new Path2D();
        var val:Int,
        n:Float,
        deg:Float,
        rad:Float,
        inc:Float = (360 / d.length),
        x:Float = 0,
        y:Float = 0;

        for (i in 0...d.length) {
            val = d[i];
            if (mod.val != null)
                val = mod.val( val );

            n = (val / 255);
            if (mod.n != null)
                n = mod.n( n );

            deg = (90 + (i * inc));
            if (mod.angle != null)
                deg = mod.angle( deg );

            rad = pos.minRadius.lerp(pos.maxRadius, n);
            if (mod.radius != null)
                rad = mod.radius( rad );

            x = pos.center.x + (cos(deg.toRadians()) * rad);
            y = pos.center.y + sin(deg.toRadians()) * rad;

            (i == 0 ? path.moveTo : path.lineTo)(x, y);
        }

        return path;
    }

    /**
      build out the Path for the Pie display
     **/
    private function buildPiePath(d:AudioData<Int>, pos:CircPos, slice:Path2D->Void, ?mod:DrawMod) {
        var path:Path2D;
        var val:Int,
        n:Float,
        deg:Array<Float>,
        rad:Float,
        inc:Float = (360 / d.length),
        x:Float = pos.center.x,
        y:Float = pos.center.y;
        for (i in 0...d.length) {
            path = new Path2D();
            val = d[i];
            if (mod.val != null)
                val = mod.val( val );
            n = (val / 255);
            if (mod.n != null)
                n = mod.n( n );
            deg = [(i * inc), (i + 1) * inc];
            rad = pos.minRadius.lerp(pos.maxRadius, n);
            path.moveTo(x, y);

            path.arc(x, y, rad, deg[0].toRadians(), deg[1].toRadians(), false);
            slice( path );
        }
    }

    /**
      build out the grid of rectangles for the 'dots' view to render in
     **/
    function buildDotsGrid() {
        //TODO
    }

    /**
      update [this]
     **/
    override function update(stage: Stage):Void {
        super.update( stage );

        calc_basic_geom();
    }

    /**
      calculate basic geometric properties
     **/
    inline function calc_basic_geom() {
        var pv = player.view;
        var pdr = displayArea;

        if (hasImg() && !drawOverImg) {
            var mr = pv.mediaRect, pvr = pv.rect;
            if (!mr.equals( pvr )) {
                var lr = new Rect(pvr.x, pvr.y, mr.x, pvr.h);
                var rr = new Rect((mr.x + mr.w), pvr.y, lr.w, pvr.h);
                displayArea = Trio(lr, mr.clone(), rr);
            }
            else {
                displayArea = Mono(mr.clone());
            }
        }
        else {
            displayArea = Mono(pv.rect.clone());
        }
    }

    @:keep
    public function setDisplayTypeString(mode: String) {
        mode = mode.trim();
        switch (mode.toLowerCase()) {
            case 'circle':
                displayType = Circle;

            case 'pie':
                displayType = Pie;

            case 'starburst', 'star':
                //TODO

            default:
                //TODO
        }
    }

    inline function isCircle():Bool return displayType.match(Circle);
    inline function isPie():Bool return displayType.match(Pie);

    inline function getImg():Null<Image> return cast(renderer, LocalAudioRenderer).albumArt;
    inline function hasImg():Bool return (getImg() != null);

    inline function lar():LocalAudioRenderer return cast(renderer, LocalAudioRenderer);

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var displayType: DisplayType;
    public var displayArea: Chan<Rect<Float>>;

    var _lblue:Null<Color> = null;
    var fill_gradient: Dynamic = null;

    var drawOverImg:Bool = false;
}

@:structInit
class DrawMod {
    @:optional public var val: Int->Int;
    @:optional public var n: Float->Float;
    @:optional public var angle: Float->Float;
    @:optional public var radius: Float->Float;
    @:optional public var data: AudioData<Int>->AudioData<Int>;
    @:optional public var pos: Point<Float>->Point<Float>;

    @:optional public var fillStyle: Dynamic;
    @:optional public var strokeStyle: Dynamic;
    @:optional public var lineWidth: Float;

/* === Instance Methods === */

    public inline function getPos(p: Point<Float>):Point<Float> {
        if (pos != null)
            p = pos( p );
        return p;
    }
}

enum DisplayType {
    Circle;
    Pie;
    Star;
}

typedef CircOp = {
    var type: DisplayType;
    var rect: Rect<Float>;
}

typedef CircPos = {
    var rect: Rect<Float>;
    var center: Point<Float>;
    var minRadius: Float;
    var maxRadius: Float;
};
