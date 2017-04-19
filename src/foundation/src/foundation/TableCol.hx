package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;
import tannus.html.Elementable;

class TableCol extends TextualWidget {
    /* Constructor Function */
    public function new(row:TableRow, ?content:Dynamic):Void {
        super();

        el = '<td></td>';
        el.data('widget', this);

        this.row = row;

        if (content != null) {
            setContent( content );
        }
    }

/* === Instance Methods === */

    /**
      * set [this] Cols content
      */
    public function setContent(content : Dynamic):Void {
        if (Std.is(content, String)) {
            el.html(cast content);
        }
        else if (Std.is(content, Element)) {
            append( content );
        }
        else if (Std.is(content, Widget)) {
            append( content );
        }
        else if (Std.is(content, Elementable)) {
            setContent(cast(content, Elementable).toElement());
        }
        else {
            throw 'Error: Cannot set column\'s content to $content';
        }
    }

/* === Instance Fields === */

    public var row : TableRow;
}
