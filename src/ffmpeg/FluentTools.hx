package ffmpeg;

import tannus.node.*;
import tannus.sys.*;
import tannus.ds.*;
import tannus.TSys.systemName;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

import pman.async.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class FluentTools {
    private static var _isWin:Null<Bool> = null;
    private static var _exeRoot:Null<Path> = null;

    public static function _gather():Void {
        if (_isWin == null) {
            _isWin = (systemName() == 'Windows');
        }
        if ( _isWin ) {
            if (_exeRoot == null) {
                _exeRoot = pman.db.AppDir.getAppPath('assets/ffmpeg-static');
            }
            Fluent.setFfmpegPath(_exeRoot.plusString('ffmpeg.exe'));
            Fluent.setFfprobePath(_exeRoot.plusString('ffprobe.exe'));
        }
    }
}
