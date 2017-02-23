package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class ImagePlayerControlButton extends IconicPlayerControlButton<Image> {
	override function drawIcon(icon:Null<Image>, c:Ctx):Void {
		if (icon == null)
			return ;
		c.drawComponent(icon, 0, 0, icon.width, icon.height, x, y, w, h);
	}
}
