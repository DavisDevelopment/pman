package foundation;

import foundation.Pane;

import tannus.math.Percent;
import tannus.io.Setter;
import Std.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

class FlexRow extends Row {
	/* Constructor Function */
	public function new(cols:Array<Int>, autoBuild:Bool=true):Void {
		super();
		
		el.css('max-width', '100%');
		if ( autoBuild )
			__buildPanes( cols );

		on('activate', function(x) {
			engage();
		});
	}

/* === Instance Methods === */

	/**
	  * Construct and attach the FlexPanes
	  */
	private function __buildPanes(list : Array<Int>):Void {
		panes = new Array();
		for (count in list) {
			addPane( count );
		}
	}

	/**
	  * Add a Pane of the specified size
	  */
	public function addPane(size : Int):FlexPane {
		var pane:FlexPane = new FlexPane();
		pane.columns.on( 'small' ).is( size );
		panes.push( pane );
		append( pane );
		return pane;
	}

	/**
	  * Remove a Pane from [this] FlexGrid
	  */
	public inline function pane(i : Int):Null<FlexPane> return panes[i];

	/**
	  * Iterate over [this]'s Panes
	  */
	public function iterator():Iterator<FlexPane> {
		return panes.iterator();
	}

	/**
	  * Set the column-count for the given breakpoint(s)
	  */
	@:access( foundation.FlexPane.FlexColumnSize )
	public function columns(breakpoint : String):Array<Int> -> Void {
		//var setters = panes.macmap(Setter.create( _.columns.sizeManager( breakpoint ).size ));
		var setters:Array<Setter<Null<Int>>> = panes.macmap( _.columns.sizeManager( breakpoint ).set_size );
		trace( setters );

		return function(sizes : Array<Int>):Void {
			var tups = setters.zip( sizes );
			for (t in tups) {
				t.left.set( t.right );
			}
		};
	}

/* === Instance Fields === */

	/* Array of Panes associated with [this] SplitPane */
	private var panes : Array<FlexPane>;
}
