package electron;

import electron.ext.Menu;
import electron.ext.MenuItem;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:forward
abstract MenuTemplate (Array<MenuItemOptions>) from Array<MenuItemOptions> to Array<MenuItemOptions> {
    public inline function new(?l : Array<MenuItemOptions>) {
        this = (l != null ? l : []);
    }

    @:to
    public inline function toMenu():Menu {
        return Menu.buildFromTemplate( this );
    }
}
