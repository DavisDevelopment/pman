package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;

class TableBody extends Widget {
    /* Constructor Function */
    public function new(t:Table):Void {
        super();

        el = '<tbody></tbody>';
        el.data('widget', this);

        table = t;
    }

/* === Instance Methods === */

    /**
      * add a Head row
      */
    public function addRow(?row : TableRow):TableRow {
        if (row == null)
            row = new TableRow( this );
        append( row );
        return row;
    }

    /**
      * get all rows
      */
    public function getRows():Array<TableRow> {
        var result = [];
        iterRows(function(row) {
            result.push( row );
        });
        return result;
    }

    /**
      * iterate over the rows
      */
    public function iterRows(f : TableRow->Void):Void {
        var children:Element = el.children('tr');
        for (child in children.toArray()) {
            var widget = child.data('widget');
            if ((widget is TableRow)) {
                f( widget );
            }
        }
    }

    /**
      * get the index of the given row
      */
    public function indexOf(row : TableRow):Int {
        var index:Int = 0;
        var children:Element = el.children('tr');
        for (child in children.toArray()) {
            if (child.data('widget') == row) {
                return index;
            }
            index++;
        }
        return -1;
    }

    /**
      * get the row at the given index
      */
    public function getRow(index : Int):Null<TableRow> {
        var rowel:Element = el.find('tr:nth-child($index)');
        if (rowel.length > 0) {
            var widget = rowel.data('widget');
            return widget;
        }
        else return null;
    }

/* === Instance Fields === */

    public var table : Table;
}
