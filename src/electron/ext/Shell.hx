package electron.ext;


#if main_process
@:jsRequire('electron', 'shell')
#elseif renderer_process
@:jsRequire('electron', 'remote.shell')
#end

extern class Shell {
	public static function showItemInFolder(fullPath : String):Bool;
	public static function openItem(fullPath : String):Bool;
	public static function openExternal(url : String):Bool;
	public static function moveItemToTrash(fullPath : String):Bool;
	public static function beep():Void;
}
