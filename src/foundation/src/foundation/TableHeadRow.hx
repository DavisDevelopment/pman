package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;

class TableHeadRow extends TextualWidget {
    /* Constructor Function */
    public function new(h:TableHead):Void {
        super();

        el = '<th></th>';
        el.data('widget', this);

        head = h;
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var head : TableHead;
}
