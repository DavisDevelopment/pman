package foundation;

import tannus.html.*;
import tannus.ds.*;

import Reflect.*;

using Reflect;

@:expose( 'hxFoundation' )
class Foundation {
/* === Static Methods === */

	/**
	  * initialize Foundation on the given Element
	  */
	public static inline function initialize(element : Element):Void {
		element.plugin( 'foundation' );
	}

	/**
	  * re-initialize Foundation for the provided plugin
	  */
	public static inline function reInitializePlugin(name : String):Void {
		l.reInit( name );
	}

	/**
	  * reinitialize a list of plugins
	  */
	public static inline function reInitializePluginList(plugins : Array<String>):Void {
		l.reInit( plugins );
	}
	
	public static inline function reInitializeElement(e : Element):Void {
		l.reInit( e );
	}

	public static inline function pluginInstance(pluginName:String, args:Array<Dynamic>):Dynamic {
		return Type.createInstance(l.getProperty( pluginName ), args);
	}

	public static function plugin<T>(name : String):Null<FoundationPlugin<T>> {
		var pc:Null<Dynamic> = l.getProperty( name );
		if (pc != null) {
			return untyped Type.createInstance.bind(pc, _).makeVarArgs();
		}
		else {
			return null;
		}
	}

/* === Static Fields === */

	/* the MediaQuery shit */
	public static var mq(get, never):MediaQuery;
	private static inline function get_mq():MediaQuery return l.MediaQuery;

	/* the underlying object */
	private static var l(get, never):Dynamic;
	private static inline function get_l():Dynamic return untyped __js__( 'window.Foundation' );

	public static var mqBreakpoints:Array<String> = {['small', 'medium', 'large', 'xlarge', 'xxlarge'];};
}

extern class MediaQuery {
	var current : String;
	function atLeast(name : String):Bool;
	function get(name : String):String;
}

private typedef FoundationPlugin<T> = Element -> Object -> T;
