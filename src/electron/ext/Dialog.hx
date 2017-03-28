package electron.ext;

#if renderer_process
@:jsRequire('electron', 'remote.dialog')
#elseif main_process
@:jsRequire('electron', 'dialog')
#end
extern class Dialog {
	@:overload(function(options:FileOpenOptions, callback:Array<String>->Void):Void {})
	@:overload(function(win:BrowserWindow, options:FileOpenOptions, callback:Array<String>->Void):Void {})
	static function showOpenDialog(callback:Array<String>->Void):Void;

	@:overload(function(options:FileDialogOptions, callback:String->Void):Void {})
	static function showSaveDialog(callback : String -> Void):Void;
}

typedef FileDialogOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<FileFilter>
};
typedef FileOpenOptions = {
	>FileDialogOptions,
	?properties:Array<FileDialogProperty>
};

@:enum
abstract FileDialogProperty (String) from String {
	var OpenFile = 'openFile';
	var OpenDirectory = 'openDirectory';
	var MultiSelections = 'multiSelections';
	var CreateDirectory = 'createDirectory';
	var ShowHiddenFiles = 'showHiddenFiles';
}
