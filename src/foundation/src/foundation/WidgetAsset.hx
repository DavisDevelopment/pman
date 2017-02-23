package foundation;

import tannus.ds.Destructible;

/**
  * Interface for an object which can be 'attached' to a Widget
  */
interface WidgetAsset extends Destructible {
	function activate():Void;
}
