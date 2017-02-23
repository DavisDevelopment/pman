package foundation;

import foundation.TextualWidget in TWidget;
import tannus.html.Element;

class Span extends TWidget {
	/* Constructor Function */
	public function new(?txt : String):Void {
		super();
		el = '<span></span>';
		if (txt != null)
			text = txt;
	}

/* === Instance Fields === */
}
