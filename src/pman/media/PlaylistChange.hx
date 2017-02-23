package pman.media;

/**
  * enum defining all the various ways in which a Playlist may be altered in-place
  */
enum PlaylistChange {
	PCInsert(pos:Int, track:Track);
	PCPop(track : Track);
	PCPush(track : Track);
	PCRemove(track : Track);
	PCReverse;
	PCClear;
	PCShift(track : Track);
	PCSort(sorter : Track->Track->Int);
	PCSplice(pos:Int, len:Int);
	PCMove(track:Track, oldPos:Int, newPos:Int);
}
