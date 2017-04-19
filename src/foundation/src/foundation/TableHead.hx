package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;

class TableHead extends Widget {
    /* Constructor Function */
    public function new(t:Table):Void {
        super();

        el = '<thead></thead>';

        table = t;
    }

/* === Instance Methods === */

    /**
      * add a Head row
      */
    public function addRow(?text : String):TableHeadRow {
        var th = new TableHeadRow( this );
        append( th );
        if (text != null) {
            th.text = text;
        }
        return th;
    }

    /**
      * add a list of head rows
      */
    public function addRows(texts : Array<String>):Array<TableHeadRow> {
        return texts.map(function( txt ) {
            return addRow( txt );
        });
    }

    /**
      * get all rows
      */
    public function getRows():Array<TableHeadRow> {
        var result = [];
        iterRows(function(row) {
            result.push( row );
        });
        return result;
    }

    /**
      * iterate over the rows
      */
    public function iterRows(f : TableHeadRow->Void):Void {
        var children:Element = el.children('th');
        for (child in children.toArray()) {
            var widget = child.data('widget');
            if ((widget is TableHeadRow)) {
                f( widget );
            }
        }
    }

/* === Instance Fields === */

    public var table : Table;
}
