package pman.media.info;

enum TrackSort {
    RelevanceTo(term : String);
    Title(ascending : Bool);
    Date(adscending : Bool);
    Views(ascending : Bool);
    Rating(ascending : Bool);
}
