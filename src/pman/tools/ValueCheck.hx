package pman.tools;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using pman.bg.DictTools;
using tannus.FunctionTools;
using tannus.html.JSTools;

enum ValueCheck {
    CheckNotNull;
    CheckType(type: ValueTypeCheck);
}

enum ValueTypeCheck {
    TBool;
    TInt;
    TFloat;
    TString;
    TObject;
    TFunction;
    TClass;
    TInstance<T>(?classType: Class<T>);
    TEnum;
    TEnumValue<T>(?enumType: Enum<T>);
    TArray;
    TMap(?keyType: ValueTypeCheck);
    TDict(?keyType: ValueTypeCheck);
}
