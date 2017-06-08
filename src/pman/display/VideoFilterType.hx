package pman.display;

import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.geom.Angle;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

enum VideoFilterType {
    Blur(size : Float);
    Brightness(amount : Float);
    Contrast(amount : Percent);
    Grayscale(amount : Percent);
    HueRotate(amount : Angle);
    Invert(amount : Percent);
    Opacity(amount : Percent);
    Saturate(amount : Percent);
    Sepia(amount : Percent);
    List(list : Array<VideoFilterType>);
}
