package pman.display;

import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.geom.Angle;

import tannus.css.Value;
import tannus.css.vals.Lexer;

import pman.display.VideoFilterType;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.css.vals.ValueTools;

class VideoFilterTools {
    /**
      * print the DOMString equivalent of the given filter
      */
    public static function toString(type : VideoFilterType):String {
        return switch ( type ) {
            case Blur( size ): 'blur(${size}px)';
            case Brightness( amount ): 'brightness($amount)';
            case Contrast( amount ): 'contrast($amount)';
            case Grayscale( amount ): 'grayscale($amount)';
            case HueRotate( amount ): 'hue-rotate(${amount.degrees}deg)';
            case Invert( amount ): 'invert($amount)';
            case Opacity( amount ): 'opacity($amount)';
            case Saturate( amount ): 'saturate($amount)';
            case Sepia( amount ): 'sepia($amount)';
            case List( list ): list.map( toString ).join(' ');
        };
    }

    /**
      * parse a String to a filter
      */
    public static function fromString(s : String):VideoFilterType {
        var vals = Lexer.parseString( s );
        var filters:Array<VideoFilterType> = new Array();
        inline function a(x : VideoFilterType) filters.push( x );
        for (v in vals) {
            switch ( v ) {
                case VCall(name, [VNumber(num, unit)]):
                    switch ( name ) {
                        case 'blur':
                            a(Blur( num ));

                        case 'brightness':
                            a(Brightness(new Percent( num )));

                        case 'contrast':
                            a(Contrast(new Percent( num )));

                        case 'grayscale':
                            a(Grayscale(new Percent( num )));

                        case 'hue-rotate':
                            a(HueRotate(new Angle( num )));

                        case 'invert':
                            a(Invert(new Percent( num )));

                        case 'opacity':
                            a(Opacity(new Percent( num )));

                        case 'saturate':
                            a(Saturate(new Percent( num )));

                        case 'sepia':
                            a(Sepia(new Percent( num )));

                        default:
                            null;
                    }

                default:
                    null;
            }
        }
        if (filters.length == 0) {
            return null;
        }
        else if (filters.length == 1) {
            return filters[0];
        }
        else {
            return List( filters );
        }
    }
}
