package electron.ext;

import tannus.geom2.Rect;
import tannus.io.ByteArray;
import tannus.node.Buffer;

import electron.ext.ExtNativeImage;
import electron.ext.ExtNativeImage as Eni;

@:forward
abstract NativeImage (Eni) from Eni to Eni {
	public inline function new(img : ExtNativeImage):Void {
		this = img;
	}

/* === Instance Methods === */

	public inline function toPNG():ByteArray return ba(this.toPNG());
	public inline function toJPEG(quality : Int):ByteArray return ba(this.toJPEG( quality ));
	public inline function toBitmap():ByteArray return ba(this.toBitmap());
	public inline function getBitmap():ByteArray return ba(this.getBitmap());
	public function getSize():Rect<Int> {
		var s = this.getSize();
		return new Rect(0, 0, s.width, s.height);
	}
	public inline function crop(x:Int, y:Int, w:Int, h:Int):NativeImage {
		return new NativeImage(this.crop({x:x, y:y, width:w, height:h}));
	}

	public static inline function createEmpty():NativeImage return Eni.createEmpty();
	public static inline function createFromPath(path : String):NativeImage return Eni.createFromPath( path );
	public static inline function createFromBuffer(buffer:Buffer, ?options:CfbOptions):NativeImage return Eni.createFromBuffer(buffer, options);
	public static inline function createFromByteArray(bytes:ByteArray, ?options:CfbOptions):NativeImage {
		return createFromBuffer(bytes.getData(), options);
	}
	public static inline function createFromDataURL(url:String):NativeImage return Eni.createFromDataURL( url );

	private static inline function ba(b : Buffer):ByteArray return ByteArray.ofData( b );
}

