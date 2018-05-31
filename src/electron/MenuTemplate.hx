package electron;

import electron.ext.Menu;
import electron.ext.MenuItem;

//import electron.main.Menu;
//import electron.main.MenuItem;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:forward
abstract MenuTemplate (Array<MenuItemOptions>) from Array<MenuItemOptions> to Array<MenuItemOptions> {
    public inline function new(?l : Array<MenuItemOptions>) {
        this = (l != null ? l : []);
        //new MenuItem()
    }

    @:to
    public inline function toMenu():Menu {
        return Menu.buildFromTemplate(cast this);
    }
}
