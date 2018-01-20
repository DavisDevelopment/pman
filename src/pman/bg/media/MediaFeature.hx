package pman.bg.media;

enum MediaFeature {
/* == Interface Types == */
    Playback;
    PlaybackSpeed;
    Display;
    DomDisplay;
    CanvasDisplay;
    Duration;
    Dimensions;
    Volume;
    Mute;
    CurrentTime;
    FutureTime;
    RecordVideo;
    RecordAudio;
    CaptureImage;
    End;

/* == Event Types == */
    EndEvent;
    LoadEvent;
}
