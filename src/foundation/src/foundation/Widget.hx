package foundation;

import foundation.Styles;
import tannus.html.ElStyles;
import foundation.WidgetAsset;

import tannus.io.EventDispatcher;
import tannus.io.Signal;
import tannus.io.Ptr;
import tannus.ds.Memory;
import tannus.ds.Object;
import tannus.ds.Destructible;
import tannus.ds.Maybe;
import tannus.math.TMath;
import tannus.geom.*;
import tannus.html.Element;
import tannus.html.Elementable;
import tannus.html.Win;

import Std.*;
import Std.is in istype;
import Math.*;
import tannus.math.TMath.*;
import tannus.internal.TypeTools;
import tannus.internal.CompileTime in Ct;
import foundation.Tools.*;

import haxe.rtti.Meta;
import tannus.ds.Obj;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;
//using foundation.Tools;

class Widget extends EventDispatcher implements WidgetAsset implements Elementable {
	/* Constructor Function */
	public function new():Void {
		super();

		__checkEvents = false;

		el = null;
		styles = new Styles(Ptr.create( el ));
		assets = new Array();
		children = new Array();
		uid = ('wi-' + Memory.allocRandomId( 6 ));

		//__ibuild();
		bindMetadataEventHandlers( this );
	}

/* === Instance Methods === */

	/**
	  * Add a Destructible Object
	  */
	public function attach(asset : WidgetAsset):Void {
		assets.push( asset );
	}

	/**
	  * Destroy [this] Widget
	  */
	public function destroy():Void {
		for (x in assets) {
			if (Std.is(x, Widget) && cast(x, Widget).childOf( this )) {
				x.destroy();
			}
			else if (!Std.is(x, Widget)) {
				x.destroy();
			}
		}
		if (el != null)
			el.remove();
	}

	/**
	  * Detach [this] Widget from the DOM
	  */
	public function detach():Void {
		toElement().detach();
	}

	/**
	  * Cast [this] Widget to an Element
	  */
	public function toElement():Element {
		return el;
	}

	/**
	  * Test a CSS-selector against [this]
	  */
	public function is(selector : String):Bool {
		if (el == null) {
			return false;
		}
		else {
			return el.is( selector );
		}
	}

	/**
	  * Engage Foundation library
	  */
	private inline function engage():Void {
		Foundation.initialize( el );
	}

	/**
	  * reset [this] Widget's plugin-data, or let Foundation know it exists
	  */
	private inline function reflow():Void {
		Foundation.reInitializeElement( el );
	}

	/**
	  * Activate [this] Widget
	  */
	public function activate():Void {
		//- mark [this] Widget as active
		_active = true;
		
		//- activate all attachments
		for (e in new Element(toElement().children()).toArray()) {
			try {
				var w:Widget = e.data( DATAKEY );
				if (w != null && !w._active) {
					w.activate();
				}
			}
			catch (error : Dynamic) {
				printError( error );
			}
		}

		//- finally, dispatch the 'activate' Event
		dispatch('activate', this);
	}

	/**
	  * Construct the layout/children of [this] Widget
	  */
	public function build():Void {
		__ibuild();
	}

	/**
	  * Populate [this] Widget with content
	  */
	private function populate():Void {
		null;
	}

	/**
	  * Internal method used to initiate the construction of [this] Widget
	  */
	private function __ibuild():Void {
		populate();
		_built = true;
		dispatch('build', this);
	}

	/**
	  * Append [this] Widget to something
	  */
	public function appendTo(parent : Dynamic):Void {
		if (Std.is(parent, Widget)) {
			var par:Widget = cast parent;
			par.append( this );
		}
		else {
			var par:Element = new Element( parent );
			par.appendElementable( this );
			parentElement = par;
			parentWidget = null;
		}

		//defer( __ac );
		__ac();
	}

	/**
	  * Append something to [this] Widget
	  */
	public function append(child : Dynamic):Void {
		_attach(child, function(l, r) l.append( r ));
	}

	/**
	  * Prepend something to [this] Widget
	  */
	public function prepend(child : Dynamic):Void {
		_attach(child, function(l, r) l.prepend( r ));
	}

	/**
	  * Insert [child] after [this]
	  */
	public function after(tail : Dynamic):Void {
		_attach(tail, function(l, r) l.after( r ));
	}

	/**
	  * Insert [child] before [this]
	  */
	public function before(head : Dynamic):Void {
		_attach(head, function(l, r) l.before( r ));
	}

	/**
	  * Attach the given object to [this] Widget, as a child
	  */
	private function _attach(child:Dynamic, attacher:Attacher):Void {
		if (istype(child, Widget)) {
			_attachWidget(cast child, attacher);
		}
		else {
			var ch:Element = new Element( child );
			var hwd:Null<Dynamic> = elementWidget( ch );

			if (hwd != null && istype(hwd, Widget)) {
				_attachWidget(cast hwd, attacher);
			}
			else {
				_attachElement(ch, attacher);
			}
		}
		//defer( __ac );
		__ac();
	}

	/**
	  * attach a Widget to [this]
	  */
	private function _attachWidget(child:Widget, attacher:Attacher):Void {
		attacher(toElement(), child.toElement());
		attach( child );
		child.parentWidget = this;
		child.parentElement = toElement();
		if ( _active ) {
			child.activate();
		}
	}

	/**
	  * attach an Element to [this]
	  */
	private function _attachElement(child:Element, attacher:Attacher):Void {
		attacher(toElement(), child);
	}

	/**
	  * Determine whether the given Object is (in some way or another) a 'child' of [this] One
	  */
	public function parentOf(child : Dynamic):Bool {
		if (Std.is(child, Widget)) {
			var cw:Widget = cast child;
			return el.contains( cw.el );
		}
		else {
			var ce:Element = new Element( child );
			return el.contains( ce );
		}
	}

	/**
	  * Determine whether the given Object is the parent of [this] one
	  */
	public function childOf(parent : Dynamic):Bool {
		if (Std.is(parent, Widget))
			return cast(parent, Widget).parentOf( parent );
		else
			return new Element( parent ).contains( el );
	}

	/**
	  * Append [child] as a child of [this], and place it at offset [index] in the array
	  */
	public function insertAt(child:Dynamic, index:Int):Void {
		if (!parentOf( child )) {
			append( child );
		}
		if (Std.is(child, Widget)) {
			el.index(cast(child, Widget).toElement(), index);
		}
		else {
			el.index(new Element( child ).at( 0 ), index);
		}
	}

	/**
	  * Replace [child] with [repl]
	  */
	public function replaceChild(child:Widget, repl:Dynamic):Void {
		if (parentOf( child )) {
			if (Std.is(repl, Widget)) {
				var rw:Widget = repl;
				child.el.replaceWith( rw.el );
			}
			else {
				child.el.replaceWith(new Element( repl ));
			}
		}
	}

	/**
	  * Replace [this] with [repl]
	  */
	public inline function replaceWith(repl : Dynamic):Void {
		if (parentWidget != null) {
			parentWidget.replaceChild(this, repl);
		}
	}

	/**
	  * animate [this] Widget
	  */
	public function animate(properties:Object, options:AnimateOptions):Void {
		var o = options;
		(untyped el.animate)(properties, {
			duration: o.duration,
			easing: o.easing,
			queue: o.queue,
			step: (function(now:Float, tween:Dynamic) if ( o.step.exists ) o.step.value( now )),
			complete: (function() if ( o.complete.exists ) o.complete.value()),
			progress: function(anim:Dynamic, progress:Float, remaining:Float):Void {
				if ( o.progress.exists ) {
					o.progress.value(progress, remaining);
				}
			}
		});
	}

	/**
	  * Ascend the widget hierarchy until a widget for which [test] returns true is found
	  */
	public function parentWidgetUntil<T:Widget>(test : Widget -> Bool):Null<T> {
		if (parentWidget != null) {
			var pw = parentWidget;
			if (test( pw )) {
				return cast pw;
			}
			else return pw.parentWidgetUntil( test );
		}
		else return null;
	}

	/**
	  * Ascend the Element hierarchy until a match is found
	  */
	public function parentElementUntil(test : Element -> Bool):Null<Element> {
		var t:Element = el.parent();
		while (t.length > 0) {
			if (test( t )) return t;
			t = t.parent();
		}
		return null;
	}

	/**
	  * define the position and area of [this]
	  */
	public function rect(?r : Rectangle):Rectangle {
		if (r == null) {
			var rr = el.at( 0 ).getBoundingClientRect();
			return new Rectangle(rr.left, rr.top, rr.width, rr.height);
		}
		else {
			pos( r.position );
			scp_float('width', r.w);
			scp_float('height', r.h);
			return rect();
		}
	}

	/**
	  * position [this]
	  */
	public function pos(?p : Point):Point {
		if (p == null) {
			var r = el.at( 0 ).getBoundingClientRect();
			return new Point(r.left, r.top);
		}
		else {
			css.write({
				'left': (p.x + 'px'),
				'top': (p.y + 'px')
			});
			return pos();
		}
	}

	private inline function get_css_property(name : String):Maybe<String> return css.get( name );
	private inline function gcp(n : String):Maybe<String> return get_css_property( n );
	private inline function gcp_float(n:String):Maybe<Float> return gcp( n ).ternary(Std.parseFloat( _ ), null);
	private inline function gcp_int(n:String):Maybe<Int> return gcp( n ).ternary(Std.parseInt(_), null);
	private inline function set_css_property(name:String, value:String):String return css.set(name, value);
	private inline function scp(n:String, v:String):String return set_css_property(n, v);
	private inline function scp_float(n:String, v:Float, unit:String='px'):Float {
		return parseFloat(scp(n, (v + unit)));
	}
	private inline function scp_int(n:String, v:Int, unit:String='px'):Int {
		return parseInt(scp(n, (v + unit)));
	}

/* === Utility Methods === */

	/**
	  * Add a class to [this] Widget
	  */
	public function addClass(name : String):Void {
		el.addClass( name );
	}
	public function addClasses(names : Iterable<String>):Void {
		names.iter( addClass );
	}

	/**
	  * Remove a class from [this] Widget
	  */
	public function removeClass(name : String):Void {
		el.removeClass( name );
	}

	/**
	  * Toggle the given class on [this] Widget
	  */
	public function toggleClass(name : String):Void {
		el.toggleClass( name );
	}

	/**
	  * Obtain an Array of classes applied to [this] Widget
	  */
	private inline function classes():Array<String> {
		return (el['class'].ternary(_.split(' '), new Array()));
	}

	/**
	  * Add some metadata to [this] Widget
	  */
	public function meta<T>(name:String, ?value:T):Null<T> {
		if (value == null) {
			return cast el.data(name);
		}
		else {
			el.data(name, value);
			return value;
		}
	}

	/**
	  * forward events from the underlying DOM into our event-system
	  */
	public function forwardEvent(name:String, ?src:Element, ?trans:Dynamic -> Dynamic):Void {
		if (src == null) 
			src = el;
		if (trans == null) 
			trans = (function(x) return untyped x);
		src.on(name, untyped function(raw_event) {
			var event = trans( raw_event );
			dispatch(name, event);
		});
	}

	/**
	  * unbind an event on the underlying DOM from our event-system
	  */
	public function unforwardEvent(name:String, ?src:Element):Void {
		if (src == null) {
			src = el;
		}

		src.unbind( name );
	}

	/**
	  * forward an Array of events
	  */
	public function forwardEvents<A, B>(names:Array<String>, ?src:Element, ?trans:A->B):Void {
		for (n in names) {
			forwardEvent(n, src, trans);
		}
	}

	/**
	  * wait for [this] to be activated
	  */
	private inline function onactivate(f : Void->Void):Void {
		if ( _active ) {
			Win.current.requestAnimationFrame(untyped f);
		}
		else {
			once('activated', untyped f);
		}
	}

	/**
	  * bind an Element to [this]
	  */
	private function __bindElement(e : Element):Void {
		e.edata.set(DATAKEY.toCamelCase(), this);
		if (!e.attributes.exists('id'))
			e['id'] = uid;
	}

	/**
	  * obtain a reference to the Widget attached to the given Element
	  */
	private inline function elementWidget(e : Element):Null<Widget> {
		return e.edata.get(DATAKEY.toCamelCase());
	}

	private function nearestWidget(ee : Element):Null<Widget> {
		var e:Null<Element> = ee;
		while (e != null) {
			var ew = elementWidget( e );
			if (ew != null) {
				return ew;
			}
			else {
				e = e.parent();
				continue;
			}
		}
		return null;
	}

	/**
	  * respond to changes to the DOM by activating stuff
	  */
	private function __ac():Void {
		if (el.containedBy( 'html' ) && !_active) {
			activate();
		}
	}

/* === Computed Instace Fields === */

	/* the Document */
	private var d(get, never):js.html.HTMLDocument;
	private inline function get_d():js.html.HTMLDocument return Win.current.document;
	
	/* the Document as an Element */
	private var doc(get, never):Element;
	private inline function get_doc() return new Element( d );

	/**
	  * The textual content of [this] Widget
	  */
	public var text(get, set) : String;
	private function get_text() return el.text;
	private function set_text(nt : String) return (el.text = nt);

	/**
	  * The width of [this] Widget
	  */
	public var width(get, set):Float;
	private function get_width() return el.w;
	private function set_width(nw) return (el.w = nw);

	/**
	  * The height of [this] Widget
	  */
	public var height(get, set):Float;
	private function get_height() return el.h;
	private function set_height(nh) return (el.h = nh);

	/* the CSS properties of [this] Widget */
	public var css(get, never):ElStyles;
	private inline function get_css():ElStyles return el.style;

	/* Underlying Element instance */
	public var el(default, set): Null<Element>;
	private function set_el(v : Null<Element>):Null<Element> {
		var ee = el;
		el = v;
		/*
		if (el != null && el != ee) {
			__bindElement( el );
		}
		*/
		return el;
	}

	/* the unique identifier for [this] Widget */
	public var uid(default, set): String;
	private function set_uid(v : String):String {
		uid = v;
		if (el != null) {
			el['id'] = uid;
		}
		return uid;
	}

/* === Instance Fields === */

	/* Array of Attached Destructibles */
	private var assets : Array<WidgetAsset>;
	private var children : Array<Widget>;

	/* A Styles instance which points to [this] Widget */
	public var styles : Styles;

	/* the parent widget of [this] one */
	public var parentWidget : Null<Widget> = null;
	public var parentElement : Null<Element> = null;

	/* Whether [this] Widget has been activated yet */
	private var _active:Bool = false;
	/* whether [this] Widget has been built yet */
	private var _built:Bool = false;

/* === Static Methods === */

	/**
	  * bind event-handlers specified via metadata
	  */
	private static function bindMetadataEventHandlers(w : Widget):Void {
		var meta:Obj = Obj.fromDynamic(Meta.getFields(Type.getClass( w )));
		var binders:Array<String> = ['on', 'once'];
		var wo:Obj = Obj.fromDynamic( w );

		for (name in meta.keys()) {
			var data:Obj = Obj.fromDynamic(meta.get( name ));
			for (key in data.keys()) {
				var params:Array<Dynamic> = data[key];
				if (binders.has( key )) {
					wo.call(key, untyped [Std.string(params[0]), wo.get( name )]);
				}
			}
		}
	}

/* === Static Fields === */

	public static inline var DATAKEY:String = 'haxe-foundation-widget';
}

typedef Attacher = Element->Element->Void;
typedef AnimateOptions = {
	?duration : Float,
	?easing: String,
	?queue: Bool,
	?step: Maybe<Float -> Void>,
	?progress: Maybe<Float -> Float -> Void>,
	?complete: Maybe<Void -> Void>
};
