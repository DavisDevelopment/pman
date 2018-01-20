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
    Seek;
    RecordVideo;
    RecordAudio;
    CaptureImage;
    End;

/* == Event Types == */
    EndEvent;
    LoadEvent;
    PlayEvent;
    CanPlayEvent;
    PauseEvent;
    LoadedMetadataEvent;
    ErrorEvent;
    ProgressEvent;
    DurationChangeEvent;
    VolumeChangeEvent;
    SpeedChangeEvent;
}
