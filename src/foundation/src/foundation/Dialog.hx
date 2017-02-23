package foundation;

import foundation.Pane;
import foundation.Link;

import tannus.html.Element;
import tannus.ds.Memory;

class Dialog extends Pane {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'reveal' );
		el['data-reveal'] = 'yes';
		el.append(createCloseButton());
		appendTo( 'body' );
		activate();
		engage();

		var fo:String->Void = el.method( 'foundation' );
		_methods = {
			open: fo.bind( 'open' ),
			close: fo.bind( 'close' ),
			toggle: fo.bind( 'toggle' ),
			destroy: fo.bind( 'destroy' )
		};
	}

/* === Instance Methods === */

	/**
	  * Open [this] Dialog
	  */
	public function open():Void {
		_methods.open();
		dispatch('open', this);
	}

	/**
	  * Close [this] Dialog
	  */
	public function close():Void {
		_methods.close();
		dispatch('close', this);
	}

	/**
	  * Toggle whether [this] is open
	  */
	public function toggle():Void {
		_methods.toggle();
	}

	/**
	  * Create and return the Element used as the close button for [this] Dialog
	  */
	private function createCloseButton():Element {
		var btn:Element = '<button class="close-button" data-close aria-label="Close modal" type="button"></button>';
		btn.append( '<span aria-hidden="true">&times;</span>' );
		return btn;
	}

/* === Computed Instance Fields === */

	/**
	  * The 'size' of [this] Dialog
	  */
	public var size(get, set):DialogSize;
	private function get_size():DialogSize {
		var t = (function(n) return el.is('.$n'));
		if (t('tiny'))
			return Tiny;
		else if (t('small'))
			return Small;
		else if (t('medium'))
			return Medium;
		else if (t('large'))
			return Large;
		else if (t('xlarge'))
			return ExtraLarge;
		else if (t('fill'))
			return Fill;
		else return null;
	}
	private function set_size(ns : DialogSize):DialogSize {
		var all = ['tiny', 'small', 'medium', 'large', 'xlarge', 'fill'];
		for (s in all) {
			removeClass( s );
		}
		addClass( ns );
		return ns;
	}

/* === Instance Fields === */

	/* Link which user may click to close [this] Dialog */
	private var closeButton : Link;

	private var _methods : DialogMethods;
}

private typedef DialogMethods = {
	function open():Void;
	function close():Void;
	function toggle():Void;
	function destroy():Void;
};

/**
  * Enum of all possible Dialog sizes
  */
@:enum
abstract DialogSize (String) from String to String {
	var Tiny = 'tiny';
	var Small = 'small';
	var Medium = 'medium';
	var Large = 'large';
	var ExtraLarge = 'xlarge';
	var Fill = 'fill';
}
