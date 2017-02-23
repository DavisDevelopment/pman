package foundation;

import foundation.Pane;
import foundation.Link;

class AlertPane extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();
		addClass('alert-box');
		el.attr('data-alert', 'yes');
		closeButton = new Link('', '#');
		closeButton.el.html('&times');
		closeButton.addClass('close');
		append(closeButton);

		addSignals(['close']);
		on('activate', function(me) {
			engage();
		});
		closeButton.on('click', function(e) {
			dispatch('close', this);
			destroy();
		});
	}

/* === Instance Methods === */

	/**
	  * Close [this] AlertPane
	  */
	public function close():Void {
		closeButton.click();
		destroy();
	}

/* === Instance Fields === */

	/* The button used to 'close' [this] Alert */
	private var closeButton : Link;
}
