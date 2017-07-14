package pman.media.info;

import tannus.ds.*;

enum TrackFilter {
    Not(filter : TrackFilter);
    And(left:TrackFilter, right:TrackFilter);
    Or(left:TrackFilter, right:TrackFilter);
    Unwatched;
    Title(op:Op, value:String);
    Duration(op:Op, value:Float);
}

enum Op {
    Eq;
    Neq;
    Has;
    Match;
    Gt;
    Gte;
    Lt;
    Lte;
}
