package foundation;

import foundation.TextualWidget;

class Paragraph extends TextualWidget {
	/* Constructor Function */
	public function new(?txt : String):Void {
		super();
		el = '<p></p>';
		if (txt != null)
			text = txt;
	}
}
