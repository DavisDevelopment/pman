package foundation;

import foundation.Pane;

import tannus.ds.*;
import tannus.html.Element;
import tannus.events.MouseEvent;

import Std.*;
import Math.*;
import tannus.math.TMath.*;

using Lambda;
using tannus.ds.ArrayTools;
using StringTools;
using tannus.ds.StringUtils;
using tannus.math.TMath;

class AccordionMenu extends List {
	/* Constructor Function */
	public function new():Void {
		super( true );

		addClasses(['vertical', 'menu']);
		el.attr('data-accordion-menu', 'yes');

		on('activated', untyped onactivate);
	}

/* === Instance Methods === */

	/**
	  * Create and return a new menu-item
	  */
	public function item(?text:String, ?href:String):MenuItem {
		var hlink = new MenuLink(this, text);
		if (href != null) hlink.href = href;
		var itm = new MenuItem(this, hlink);
		append( itm );
		// reflow();
		return itm;
	}

	/**
	  * initialize [this] shit
	  */
	private function onactivate():Void {
		var f = Foundation.plugin( 'AccordionMenu' );
		nam = f(el, {});
	}

/* === Instance Fields === */

	private var nam : Nam;
}

@:access( foundation.AccordionMenu )
class MenuItem extends ListItem {
	/* Constructor Function */
	public function new(m:AccordionMenu, l:MenuLink):Void {
		super( m );

		menu = m;
		link = l;
		sub_menu = null;
		append( link );
		__events();
	}

/* === Instance MEthods === */

	override public function append(what : Dynamic):Void {
		if (Std.is(what, AccordionMenu)) {
			var am = cast(what, AccordionMenu);
			am.addClass( 'nested' );
			if (sub_menu != null && sub_menu != am) {
				sub_menu.destroy();
			}
			sub_menu = am;
		}

		super.append( what );
	}

	/**
	  * attach an item to [this]'s submenu
	  */
	public function item(?text:String, ?href:String):MenuItem {
		var itm = sm().item(text, href);
		return itm;
	}

	/**
	  * attach a sub-menu to [this] item
	  */
	public function submenu():AccordionMenu {
		if (sub_menu == null) {
			sub_menu = new AccordionMenu();
			append( sub_menu );
		}
		return sub_menu;
	}
	private inline function sm():AccordionMenu return submenu();

	/**
	  * open [this] sub-menu
	  */
	public function down():Void {
		menu.nam.down( sub_menu.el );
	}

	/**
	  * listen for events
	  */
	private function __events():Void {
		forwardEvent('click', link.el, MouseEvent.fromJqEvent);
		forwardEvents(['down.zf.accordionMenu', 'up.zf.accordionMenu']);
	}

/* === Computed Instance Fields === */

	public var title(get, set):String;
	private inline function get_title():String return link.text;
	private inline function set_title(v : String):String return (link.text = v);

/* === Instance Fields === */

	public var menu : AccordionMenu;
	public var link : MenuLink;
	public var sub_menu : Null<AccordionMenu>;
}

/**
  * hyperlink element in a menu
  */
class MenuLink extends Link {
	/* Constructor Function */
	public function new(m:AccordionMenu, txt:String=''):Void {
		super();

		text = txt;
		href = '#';
		menu = m;
	}

	private var menu : AccordionMenu;
}

/**
  * extern for the actual instance of the Foundation.AccordionMenu class
  * -------------
  * 'Nam' => "NAM" => N(ative) A(ccordion) M(enu)
  */
extern class Nam {
	function hideAll():Void;
	function toggle(e : Element):Void;
	function down(e : Element):Void;
	function up(e : Element):Void;
	function destroy():Void;
}
