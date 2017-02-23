package vex.svg;

#if foundation

import foundation.Widget;

@:access( vex.svg.SVGDocument )
@:access( vex.svg.SVGElement )
class DocumentWidget extends Widget {
	/* Constructor Function */
	public function new(?d : SVGDocument):Void {
		super();

		svg = (d != null ? d : new SVGDocument());

		el = svg.svg;
	}

/* === Instance Methods === */

	/**
	  * Append [child] to [this]
	  */
	override public function append(child : Dynamic):Void {
		if (Std.is(child, SVGElement)) {
			svg.append(cast child);
		}
		else {
			super.append( child );
		}
	}

/* === Instance Fields === */

	public var svg : SVGDocument;
}

#else

typedef DocumentWidget = Dynamic;

#end
