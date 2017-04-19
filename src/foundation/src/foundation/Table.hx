package foundation;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;

class Table extends Widget {
    /* Constructor Function */
    public function new():Void {
        super();

        el = '<table></table>';

        header = new TableHead( this );
        append( header );
        body = new TableBody( this );
        append( body );

        el.data('widget', this);
    }

/* === Instance Methods === */

    /**
      * add a header row
      */
    public inline function addHeadRow(?text : String):TableHeadRow return header.addRow( text );
    public inline function addHeadRows(texts:Array<String>):Array<TableHeadRow> return header.addRows(texts);

    /**
      * get all header rows
      */
    public inline function getHeadRows():Array<TableHeadRow> return header.getRows();

    /**
      * iterate over header rows
      */
    public inline function iterHeadRows(f : TableHeadRow->Void):Void header.iterRows(f);

    /**
      * add a Row to the body
      */
    public inline function addRow(?row : TableRow):TableRow return body.addRow( row );
    public inline function iterRows(f : TableRow->Void):Void body.iterRows( f );
    public inline function getRows():Array<TableRow> return body.getRows();

/* === Instance Fields === */

    public var header : TableHead;
    public var body : TableBody;
}
