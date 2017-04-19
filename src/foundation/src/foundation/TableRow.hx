package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;

class TableRow extends Widget {
    /* Constructor Function */
    public function new(tb:TableBody):Void {
        super();

        el = '<tr></tr>';
        el.data('widget', this);

        body = tb;
    }

/* === Instance Methods === */

    /**
      * add a Head row
      */
    public function addCol(?col:TableCol, ?content:Dynamic):TableCol {
        if (col == null)
            col = new TableCol(this, content);
        else if (content != null)
            col.setContent( content );
        append( col );
        return col;
    }

    /**
      * get all rows
      */
    public function getCols():Array<TableCol> {
        var result = [];
        iterCols(function(col) {
            result.push( col );
        });
        return result;
    }

    /**
      * iterate over the rows
      */
    public function iterCols(f : TableCol->Void):Void {
        var children:Element = el.children('td');
        for (child in children.toArray()) {
            var widget = child.data('widget');
            if ((widget is TableCol)) {
                f( widget );
            }
        }
    }

/* === Instance Fields === */

    public var body : TableBody;
}
