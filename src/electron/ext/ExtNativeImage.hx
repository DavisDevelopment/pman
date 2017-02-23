package electron.ext;

import tannus.node.Buffer;

#if main_process
@:jsRequire('electron', 'nativeImage')
#elseif renderer_process
@:jsRequire('electron', 'remote.nativeImage')
#end
extern class ExtNativeImage {
	public function toPNG():Buffer;
	public function toJPEG(quality : Int):Buffer;
	public function toBitmap():Buffer;
	public function toDataURL():String;
	public function getBitmap():Buffer;
	public function isEmpty():Bool;
	public function getSize():{width:Int, height:Int};
	public function setTemplateImage(v : Bool):Void;
	public function isTemplateImage():Bool;
	public function crop<T:RectLike>(rect : T):ExtNativeImage;
	public function getAspectRatio():Float;

	public static function createEmpty():ExtNativeImage;
	public static function createFromPath(path : String):ExtNativeImage;
	public static function createFromBuffer(buffer:Buffer, ?options:CfbOptions):ExtNativeImage;
	public static function createFromDataURL(url : String):ExtNativeImage;
}

typedef CfbOptions = {
	?width : Int,
	?height : Int,
	?scaleFactor : Float
};

private typedef RectLike = {
	x : Int,
	y : Int,
	width : Int,
	height : Int
};
