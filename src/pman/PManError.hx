package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.sys.Path;

enum PManError {
    // TODO
    PMESystemError;

    // fs errors
    PMEFileSystemError(e: PManFileSystemError);

    // TODO
    PMEDatabaseError;

    // media errors
    PMEMediaError(e: PManMediaError);
}

/*
   represents an error related to the media system
*/
enum PManMediaError {
    // wraps around a native MediaError
    EMediaObjectError(e: js.html.MediaError);

    // invalid/malformed URI
    EMalformedURIError(uri: String);
}

/*
   represents an error related to the FileSystem
*/
enum PManFileSystemError {
    // invalid/malformed FileSystem path
    EMalformedPathError(path: String);

    //TODO wraps around an EdisFileSystemError value
    EEdisFileSystemError;
    
    //TODO wraps around a TannusFileSystemError value
    ETannusFileSystemError;
}
