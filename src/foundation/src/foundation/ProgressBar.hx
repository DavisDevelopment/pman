package foundation;

import foundation.Pane;

import tannus.html.Element;
import tannus.math.Percent;
import tannus.graphics.Color;

class ProgressBar extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();
		addClass('progress');
		meter = '<span class="meter"></span>';
		meter.css('width', '0%');
		append( meter );
	}

/* === Computed Instance Fields === */

	/**
	  * The progress
	  */
	public var progress(get, set):Percent;
	private inline function get_progress() return new Percent(Std.parseFloat(meter.css('width')));
	private function set_progress(np : Percent):Percent {
		meter.css('width', np.toString());
		return progress;
	}

	/**
	  * The Color of the meter
	  */
	public var color(get, set):Color;
	private function get_color():Color {
		return Color.fromString(el.css('background-color'));
	}
	private function set_color(nc : Color):Color {
		el.css('background-color', nc.toString());
		return nc;
	}

	/**
	  * The color of the meter
	  */
	public var meterColor(get, set):Color;
	private function get_meterColor() {
		return Color.fromString(meter.css('background-color'));
	}
	private function set_meterColor(mc : Color):Color {
		meter.css('background-color', mc.toString());
		return mc;
	}

/* === Instance Fields === */

	private var meter : Element;
}
