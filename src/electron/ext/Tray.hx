package electron.ext;

import tannus.node.EventEmitter;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

@:forward
abstract Tray (NTray) from NTray to NTray {
	/* Constructor Function */
	public inline function new(icon : EitherType<String, NativeImage>):Void {
		this = new NTray( icon );
	}

/* === Instance Methods === */

	public inline function onClick(handler : TrayClickEvent -> js.html.Rect -> Void):Void on('click', handler);

	public inline function on<T:Function>(name:String, handler:T):Void this.on(name, handler);
	public inline function once<T:Function>(name:String, handler:T):Void this.once(name, handler);
	public inline function off(name:String, handler:Function):Void this.removeListener(name, handler);
}

#if main_process
@:jsRequire('electron', 'Tray')
#elseif renderer_process
@:jsRequire('electron', 'remote.Tray')
#end
extern class NTray extends EventEmitter {
	public function new(icon : EitherType<String, NativeImage>):Void;

	public function destroy():Void;
	public function setImage(icon : EitherType<String, NativeImage>):Void;
	public function setTooltip(tooltip : String):Void;
	public function setContextMenu(menu : Menu):Void;
	//public function 
}

typedef TrayClickEvent = {
	altKey:Bool,
	shiftKey:Bool,
	ctrlKey:Bool,
	metaKey:Bool
};
