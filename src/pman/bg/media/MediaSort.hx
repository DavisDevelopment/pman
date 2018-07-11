package pman.bg.media;

enum MediaSort {
    MSTitle(ascending: Bool);
    MSDuration(ascending: Bool);
    MSDate(type:MediaDate, adscending:Bool);
    MSViews(ascending : Bool);
    MSRating(ascending : Bool);
    MSNone;
}

enum MediaDate {
    MDCreated;
    MDModified;
}
