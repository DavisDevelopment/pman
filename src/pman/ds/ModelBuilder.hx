package pman.ds;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.TSys as Sys;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.TypedExprTools;
using haxe.macro.ComplexTypeTools;
using tannus.macro.MacroTools;

class ModelBuilder {
    public static function build() {
        var localType:Type = Context.getLocalType();
        switch localType {
            case TInst(_, [param]):
                var spec = getInf( param );
                if (spec == null)
                    return null;
                else {
                    var impl = getModelClass(spec, Context.currentPos());
                    //trace(impl.toComplexType().toString());

                    return impl;
                }

            default:
                Context.error('Class expected', Context.currentPos());
        }

        return null;
    }

    static function getModelClass(info:Inf, pos:Position):Null<Type> {
        if (info.spec.hasName()) {
            var pname:String = info.spec.fullName();
            try {
                var ptype = info.spec.toPathType(true);
                if (ptype.sub != null)
                    ptype.name = ptype.sub;
                ptype.params = null;
                var rtype = ComplexType.TPath( ptype );
                //trace(rtype.toString());
                return Context.resolveType(rtype, Context.currentPos());
            }
            catch (err: Dynamic) {
                //try {
                    var mcdef = createModelClass(info, pos);
                    Context.defineType( mcdef );
                    return getModelClass(info, pos);
                //}
                //catch (err: Dynamic) {
                    //trace( err );

                    //return null;
                //}
            }
        }
        else {
            Context.error('Type must have a name', Context.currentPos());
        }
        return null;
    }

    /**
      generate implementation class
     **/
    static function createModelClass(info:Inf, pos:Position) {
        var names:Array<String> = ['Attr', 'get', 'set', 'has', 'delete'];
        inline function nam(index, ?suffix):String {
            return names[index+1] + (suffix!=null?suffix:names[0]);
        }

        /**
          create new class definition
         **/
        var mc:TypeDefinition = macro class ModelOf extends pman.ds.Model {
            /* Constructor Function */
            public function new():Void {
                super();

                //PROPERTIES;
                trace('betty');
            }
        }

        var pct:ComplexType = info.type.toComplexType();
        var pak = info.spec.toPathType(true);
        mc.pack = pak.pack;
        mc.name = (pak.sub != null ? pak.sub : pak.name);

        var initExprs:Array<Expr> = [];
        var ofields = info.spec.getFieldArray();
        var meta:MetaAccess;
        for (field in ofields) {
            meta = field.meta;

            if (meta.has(':noModel'))
                continue;

            switch field.kind {
                case FVar(_, _):
                    var vfl = genVarFieldsFor(field, initExprs.push);
                    for (x in vfl)
                        mc.fields.push(x);
                    
                    var fe = field.expr();
                    if (fe != null) {
                        initExprs.push(macro {
                            $i{field.name} = ${Context.getTypedExpr(fe)};
                        });
                    }

                case FMethod(mkind):
                    var fi = getFuncInfo( field.type );
                    var fe = field.expr(), body:Null<Expr>;
                    if (fe == null)
                        body = null;
                    else
                        body = Context.getTypedExpr( fe );

                    var func:Function = {
                        args: cast fi.args.map(arg -> cast {
                            name: arg.name,
                            opt: arg.opt,
                            type: arg.t.toComplexType()
                        }),
                        expr: null,
                        ret: fi.ret.toComplexType()
                    };

                    if (body != null) {
                        switch body.expr {
                            case EFunction(name, ff) if (ff.expr != null):
                                body = ff.expr;
                            case EParenthesis({pos:_, expr:EFunction(name, ff)}) if (ff.expr != null):
                                body = ff.expr;
                            case _:
                                throw 'Unsupported method expression type';
                        }

                        func.expr = body;
                    }
                    else {
                        func.expr = {
                            throw 'Not Implemented';
                        };
                    }

                    mc.fields.push({
                        name: field.name,
                        pos: Context.currentPos(),
                        access: [APublic, AInline],
                        kind: FFun( func )
                    });

                case _:
                    //
            }
        }

        /**
          if [initExprs] is non-empty, override the _init_ method and add the
          specified initialization expressions to the override method
         **/
        if (!initExprs.empty()) {
            mc.fields.push({
                name: '_init_',
                pos: Context.currentPos(),
                access: [AOverride],
                kind: FFun({
                    args: [],
                    ret: null,
                    expr: (macro {
                        super._init_();
                        $b{initExprs};
                    })
                })
            });
        }
        
        return mc;
    }

    static function genVarFieldsFor(field:ClassField, appendInit:Expr->Int):Array<Field> {
        var fields = [
            genVarFieldGetter(field, appendInit),
            genVarFieldSetter(field, appendInit)
        ];
        
        fields.push({
            name: field.name,
            pos: Context.currentPos(),
            access: [APublic],
            kind: FProp('get', 'set', field.type.toComplexType())
        });

        return fields;
    }

    static function genVarFieldGetter(field:ClassField, appendInit:Expr->Int):Field {
        var method:String = 'getAttr', isProperty:Bool = false;

        if (field.meta.has(':noSave')) {
            trace('[== NO-SAVE ==]');
        }
        
        var getter:Field = ({
            name: ('get_' + field.name),
            pos: Context.currentPos(),
            access: [AInline],
            kind: FFun({
                args: [],
                expr: (macro return this.$method($v{field.name})),
                ret: null
            })
        });

        return getter;
    }

    static function genVarFieldSetter(field:ClassField, appendInit:Expr->Int):Field {
        var method:String = 'setAttr', isProperty:Bool = false;

        if (field.meta.has('@:noSave')) {
            //
        }

        var setter:Field = ({
            name: ('set_' + field.name),
            pos: Context.currentPos(),
            access: [AInline],
            kind: FFun({
                args: [{name:'v', type:null}],
                expr: (macro return this.$method($v{field.name}, cast v)),
                ret: null
            })
        });

        return setter;
    }

    static function getInf(t: Type):Null<Inf> {
        return
            if (hasFields( t ))
                ({type:t, spec:getTSpec(t)});
            else null;
    }

    static function getTSpec(t: Type):Null<Spec> {
        //return (hasFields( t ) ? new Spec(getFields( t ), getNameInfo( t )) : null);
        if (hasFields( t )) {
            return cast {
                type: t,
                fields: getFields( t ),
                pathName: getNameInfo( t )
                //params: getTypeParams( t )
            };
        }
        else {
            return null;
        }
    }

    static function getFuncInfo(t: Type) {
        return switch t {
            case TFun(args, ret): {args:args, ret:ret};
            case TLazy(get): getFuncInfo(get());
            case TMono(_.get()=>mono):
                if (mono != null)
                    getFuncInfo( mono );
                else null;
            case Type.TType(_.get()=>tt, _): getFuncInfo( tt.type );
            case Type.TAbstract(_.get()=>ab, _): getFuncInfo( ab.type );
            case _: null;
        };
    }

    static function hasTypeParams(t: Type):Bool {
        return (getTypeParams(t).hasContent());
    }

    static function getTypeParams(t: Type):Null<Array<TypeParameter>> {
        return switch t {
            case TAnonymous(_.get()=>anon): null;
            case TInst(_.get()=>cl, _): cl.params;
            case TType(_.get()=>tt, _): tt.params;
            case TAbstract(_.get()=>ab, _): ab.params;
            case TMono(_.get()=>mono): 
                if (mono != null)
                    getTypeParams(mono);
                else
                    null;
            case TLazy(get): getTypeParams(get());
            case _: null;
        };
    }

    static function getComplexTypeParameters(ct: ComplexType) {
        return switch ct {
            case ComplexType.TAnonymous(_): null;
            case ComplexType.TExtend(_, _): null;
            case ComplexType.TFunction(_, _): null;
            case ComplexType.TParent(t): getComplexTypeParameters( t );
            case ComplexType.TOptional(t): getComplexTypeParameters( t );
            case ComplexType.TPath(path): path.params;
            case _: null;
        };
    }

    static function hasFields(t: Type):Bool {
        return switch t {
            case TAnonymous(_)|TInst(_,_): true;
            case TType(_.get()=>tt, _): hasFields(tt.type);
            default: false;
        };
    }

    static function getFields(t: Type):Null<Array<ClassField>> {
        switch t {
            case TInst(_.get()=>cl, _):
                return cl.fields.get();
            case TAnonymous(_.get()=>a):
                return a.fields;
            case TType(_.get()=>tt,_):
                return getFields( tt.type );
            default:
                return null;
        }
    }

    static function getNameInfo(t: Type):Null<Array<String>> {
        return switch t {
            case TInst(_.get()=>cl, _): computeFullName(cl.name, cl.module, cl.pack);
            case TAbstract(_.get()=>ab, _): computeFullName(ab.name, ab.module, ab.pack);
            case TEnum(_.get()=>en, _): computeFullName(en.name, en.module, en.pack);
            case TType(_.get()=>tt, _): computeFullName(tt.name, tt.module, tt.pack);
            default: null;
        };
    }

    static function hasNameInfo(t: Type):Bool {
        return switch t {
            case TInst(_, _),TAbstract(_, _), TEnum(_, _), TType(_, _): true;
            default: false;
        };
    }

    static function computeFullName(name:String, module:String, pack:Array<String>):Array<String> {
        var a = module.split('.');
		if (!a.last().empty() && name != a.last())
			a.push( name );
		return a;
    }

    static function typeReplace(type:Type, twhat:Type, twith:Type):Type {
        return type.map(type_replace_mapper.bind(_, twhat, twith));
    }

    static function type_replace_mapper(type:Type, twhat:Type, twith:Type):Type {
        if (type.equals(twhat) || Context.unify(type, twhat)) {
            return twith;
        }
        else {
            return type;
        }
    }

    static function alphabet():Array<String> {
        var letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        return letters.split('');
    }
}

private typedef SpecType = {
    var type: Type;
    var pathName: Null<Array<String>>;
    //var params: Null<Array<TypeParameter>>;
    var fields: Map<String, ClassField>;
}

private typedef Inf = {
    var type: Type;
    var spec: Spec;
}

@:forward
private abstract Spec (SpecType) from SpecType to SpecType {
    public function new(fields:Array<ClassField>, type:Type, ?name:Array<String>, ?params:Array<TypeParameter>) {
        this = {
            pathName: name,
            type: type,
            fields: [for (f in fields) f.name => f]
            //params: params
        };
    }

    public inline function hasName():Bool {
        return (this.pathName != null);
    }

    public inline function fullName():String {
        return (hasName() ? this.pathName.join('.') : '');
    }

    public function pack():Array<String> {
        var a = this.pathName.copy();
        while (CAPITAL.match(a[a.length - 1]))
            a.pop();
        return a;
    }

    public function name():String {
        return this.pathName.last();
    }

    static inline function _path(ct: ComplexType):TypePath {
        return switch ct {
            case ComplexType.TPath(path): path;
            case _: throw 'Wtf';
        };
    }

    public var params(get, never):Null<Array<TypeParameter>>;
    private inline function get_params() {
        return @:privateAccess ModelBuilder.getTypeParams( this.type );
    }

    function _toPathType(modelType:Bool=false):TypePath {
        var ct = this.type.toComplexType();
        if (ct == null)
            return null;
        else {
            var path:TypePath = _path( ct ).passTo(p -> cast {
                pack: p.pack.copy(),
                name: p.name,
                sub: p.sub,
                params: p.params
            });
            if (path.name == path.sub) {
                path.sub = null;
            }
            if ( modelType ) {
                if (path.sub != null) {
                    path.sub = 'ModelFor${path.sub}';
                }
                else {
                    path.name = 'ModelFor${path.name}';
                }
            }
            return path;
        }
        /*
        var p = this.pathName;
        var sl = p[p.length - 2], l = p[p.length - 1];
        if (CAPITAL.match( sl )) {
            return {
                name: sl,
                sub: (modelType ? 'ModelFor$l' : l),
                pack: p.slice(0, -2)
            };
        }
        else {
            return {
                name: (modelType ? 'ModelFor$l' : l),
                pack: p.slice(0, -1)
            };
        }
        */
    }

    public function toPathType(modelType:Bool=false):TypePath {
        var tp = _toPathType( modelType );
        return tp;
    }

    public function toComplexType(modelType:Bool=false):ComplexType {
        return ComplexType.TPath(toPathType( modelType ));
    }

    @:arrayAccess
    public inline function getField(n: String):Null<ClassField> {
        return this.fields.get( n );
    }

    @:arrayAccess
    public inline function setField(n:String, f:ClassField):ClassField return this.fields[n] = f;

    public inline function addField(field:ClassField, ?n:String) {
        if (n != null) {
            field.name = n;
        }
        setField(field.name, field);
    }

    public inline function addFields(arr: Array<ClassField>) {
        for (x in arr) {
            addField( x );
        }
    }

    public inline function deleteField(n: String):Bool {
        return this.fields.remove( n );
    }

    public inline function getFieldArray():Array<ClassField> {
        return [for (x in this.fields) x];
    }

    public static var CAPITAL:EReg = ~/^[A-Z]/g;
}
