package electron.ext;

import haxe.Constraints.Function;

import electron.ext.ExtApp;
import electron.ext.ExtApp in A;

import tannus.sys.Path;

class App {
/* === Class Methods === */

	/**
	  * wait for [this] App to be ready
	  */
	public static inline function onReady(callback : Void->Void):Void {
		on('ready', callback);
	}

	public static inline function quit():Void A.quit();
	public static inline function exit(?code : Int):Void A.exit(code);
	public static inline function relaunch(?options : ExtAppRelaunchOptions):Void A.relaunch( options );
	public static inline function isReady():Bool return A.isReady();
	public static inline function focus():Void A.focus();

	public static inline function getAppPath():Path return new Path(A.getAppPath());
	public static inline function getPath(name : ExtAppNamedPath):Path return new Path(A.getPath( name ));

	public static inline function getVersion():String return A.getVersion();
	public static inline function getName():String return A.getName();
	public static inline function on(name:String, f:Function):Void A.on(name, f);
}
