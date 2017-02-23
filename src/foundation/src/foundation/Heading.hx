package foundation;

import foundation.TextualWidget;

class Heading extends TextualWidget {
	/* Constructor Function */
	public function new(lvl:Int, ?txt:String):Void {
		super();

		el = '<h$lvl></h$lvl>';
		if (txt != null)
			text = txt;
	}
}
