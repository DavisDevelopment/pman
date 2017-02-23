package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.ext.*;

import gryffin.core.*;
import gryffin.display.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Assets {
	// get the app path
	private static inline function ad():Path return App.getAppPath();
	public static inline function getAssetsPath():Path return ad().plusString( 'assets' );
	public static inline function getIconPath(id : String):Path {
		return getAssetsPath().plusString( 'icons/$id' );
	}

	public static function loadIcon(id : String):Image {
		return Image.load('file://${getIconPath( id )}');
	}
}
