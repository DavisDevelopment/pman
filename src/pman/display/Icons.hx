package pman.display;

import gryffin.display.*;

import vex.core.*;

import tannus.io.*;
import tannus.ds.*;
import tannus.internal.CompileTime in Ct;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class Icons {
	/**
	  * Play icon
	  */
	public static function playIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'play', f);
	}

	/**
	  * Pause icon
	  */
	public static function pauseIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'pause', f);
	}

	/**
	  * Previous icon
	  */
	public static function prevIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'previous', f);
    }

	/**
	  * Next icon
	  */
	public static function nextIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'next', f);
    }

	/**
	  * Expand icon
	  */
	public static function expandIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'expand', f);
    }

	/**
	  * collapse icon
	  */
	public static function collapseIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'collapse', f);
    }

	/**
	  * clock icon
	  */
	public static function clockIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'clock', f);
    }

	/**
	  * mute icon
	  */
	public static function muteIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'sound-muted', f);
    }

	/**
	  * shuffle icon
	  */
	public static function shuffleIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'shuffle', f);
    }

	/**
	  * back icon
	  */
	public static function backIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'back', f);
    }

	/**
	  * volume icon
	  */
	public static function volumeIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'sound3', f);
	}

	/**
	  * selection-expand icon
	  */
	public static function selectionExpand(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'selection-expand', f);
	}

	/**
	  * selection-collapse icon
	  */
	public static function selectionCollapse(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'selection-collapse', f);
	}

	/**
	  * cog icon
	  */
	public static function cogIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'cog', f);
    }

	/**
	  * clear icon
	  */
	public static function clearIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'clear', f);
    }

	/**
	  * repeat icon
	  */
	public static function repeatIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'repeat', f);
    }

	/**
	  * close icon
	  */
	public static function closeIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'close', f);
    }

	/**
	  * create the Chromecast icon
	  */
	public static function castIcon(w:Int, h:Int, ?f:Path->Void):Document {
		return namedPath(w, h, 'cast', f);
	}

	/**
	  * list icon
	  */
	public static function listIcon(w:Int, h:Int, ?f:Path->Void):Document {
	    return namedPath(w, h, 'list', f);
	}

	public static function starIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'star', f);

	public static function tagIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'tag', f);

	public static function ribbonIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'ribbon', f);

	public static function heartIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'heart.hollow', f);

	public static function folderIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'folder', f);

	public static function deleteIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'delete', f);
	public static function filmIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'film', f);
	public static function infoIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'info', f);
	public static function musicIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'music', f);
	public static function plusIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'plus', f);
	public static function saveIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'save', f);
	public static function codeIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'code', f);
	public static function editIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'edit', f);
	public static function editPlusIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'edit.plus', f);
	public static function editMinusIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'edit.minus', f);
	public static function minusIcon(w:Int, h:Int, ?f:Path->Void):Document return namedPath(w, h, 'minus', f);

	/**
	  * Utility method for creating a <path> from a command string stored in [icon_data]
	  */
	public static function namedPath(w:Int, h:Int, name:String, ?f:Path->Void):Document {
		return spath(w, h, icon_data.get( name ), f);
	}

	/**
	  * Utility method for creating a <path> from a command string
	  */
	public static function spath(w:Int, h:Int, d:String, ?f:Path->Void):Document {
		return path(w, h, function(p) {
			p.d = d;
			p.style.fill = '#E6E6E6';
			/*
			p.style.stroke = '#E6E6E6';
			p.style.strokeWidth = 2;
			*/
			if (f != null) f( p );
		});
	}

	/**
	  * Utility method for creating an svg document whose sole element is a <path>
	  */
	public static function path(w:Int, h:Int, f:Path->Void):Document {
		return icon(w, h, function( svg ) {
			var path = new Path();
			svg.append( path );
			f( path );
		});
	}
	
	/**
	  * Utility method for creating an svg document
	  */
	public static function icon(w:Int, h:Int, f:Document->Void):Document {
		var svg = new Document();
		svg.width = w;
		svg.height = h;
		svg.viewBox = [76, 76];

		f( svg );

		return svg;
	}

	/**
	  * get some icon-data by name
	  */
	private static function get(name : String):String {
		return icon_data.get( name );
	}

	/**
	  * Initialize [this] class
	  */
	public static function __init__():Void {
		icon_data = Ct.readJSON( 'assets/icons/icon_data.json' );
		/*
		var rd:Object = new Object( raw_icon_data );
		icon_data = new Dict();
		for (key in rd.keys) {
			icon_data.set(key, rd.get( key ));
		}
		*/
	}

/* === Static Fields === */

	private static var icon_data : Object;
}
