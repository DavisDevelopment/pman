package pman.models;

import haxe.ds.Option;

import Slambda.fn;

using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.OptionTools;

class Tree <Item> {
    /* Constructor Function */
    public function new() {
        firstNode = new RootTreeNode();
    }

/* === Methods === */

/* === Variables === */

    public var firstNode(default, null): Null<Any>;
}

@:allow(pman.models.Tree)
class TreeNodeBase<T> {
    /* Constructor Function */
    public function new(?firstChild:TreeNode<T>) {
        this.next = Option.None;
        this.firstChild = Option.None;
        this.parentNode = Option.None;

        if (firstChild != null)
            this.firstChild = Option.Some(firstChild);
    }

/* === Methods === */

    public function after(node: TreeNodeBase<T>) {
        var tmp = this.next;
        this.next = cast Some(cast node);
        node.next = tmp;
        return node;
    }

    public function before(node: TreeNodeBase<T>):TreeNodeBase<T> {
        for (n in siblings()) {
            switch n.next {
                case Some(nn) if (nn == this):
                    return n.after(node);

                case _:
                    continue;
            }
        }

        node.after( this );
        return node;
    }

    public function append(node: TreeNodeBase<T>):TreeNodeBase<T> {
        switch next {
            case Some(next):
                return next.append( node );

            case None:
                return after( node );
        }
    }

    function getLastSiblingNode():Option<TreeNodeBase<T>> {
        return fnf(fn(!_.hasNext()), fn(Some(_)), fn(None));
    }

    function fnf<O>(chk:TreeNodeBase<T>->Bool, some:TreeNodeBase<T>->O, ?none:Void->O):O {
        if (none == null) {
            untyped {
                none = (function() { throw new pman.Errors.ValueError(null, 'No TreeNode matched'); });
            }
        }
        var it = iterator();
        while (it.hasNext()) {
            switch it.next() {
                case node if (chk( node )):
                    return some(node);

                case _:
                    continue;
            }
        }
        return none();
    }

    public function adopt(node: TreeNodeBase<T>):TreeNodeBase<T> {
        node.parentNode = Some(this);
        return node;
    }

    public function adoptSibling(node: TreeNodeBase<T>):TreeNodeBase<T> {
        return switch parentNode {
            case None: node;
            case Some(x): x.adopt(node);
        }
    }

    public function siblings():Iterator<TreeNodeBase<T>> {
        return switch parentNode {
            case None: EmptyIter.make();
            case Some(parentNode): parentNode.children();
        }
    }

    public function iterator():Iterator<TreeNodeBase<T>> {
        return new NodeTreeNodeIterator(Some(this));
    }

    public function children():Iterator<TreeNode<T>> {
        return new NodeTreeNodeIterator(firstChild);
    }

    public inline function hasNext():Bool {
        return next.isSome();
    }

    public inline function getNext():Null<TreeNodeBase<T>> {
        return next.getValue();
    }

    public inline function hasChildren():Bool {
        return firstChild.isSome();
    }

/* === Variables === */

    //public var value(default, null): T;
    public var next(default, null): Option<TreeNode<T>>;
    public var firstChild(default, null): Option<TreeNode<T>>;
    public var parentNode(default, null): Option<TreeNodeBase<T>>;
}

class NilTreeNode<T> extends TreeNodeBase<T> {}
class RootTreeNode<T> extends NilTreeNode<T> {
    override function iterator() {
        return cast EmptyIter.make();
    }
}

class TreeNode<T> extends TreeNodeBase<T> {
    /* Constructor Function */
    public function new(value:T, ?firstChild:TreeNode<T>) {
        super( firstChild );

        this.value = value;
    }

/* === Variables === */

    public var value(default, null): T;
}

class EmptyIter<T> {
    public function new() { }
    public function hasNext():Bool return false;
    public function next():T throw 0;

    static var inst = new EmptyIter();

    public static function make<T>():EmptyIter<T> {
        return cast inst;
    }
}

class SingleIter<T> {
    public function new(v: T) {
        this.v = Some(v);
    }

    public inline function hasNext():Bool {
        return v.isSome();
    }

    public function next():T {
        return switch v {
            case Some(ret):
                v = None;
                ret;

            case None:
                #if debug
                throw 'iterator has ended. next() should not be called';
                #else
                return null;
                #end
        }
    }

    var v(default, null): Option<T>;
}

class TreeNodeIterator<TIn, TOut, TNode:TreeNodeBase<TIn>> {
    /* Constructor Function */
    public function new(node) {
        this.node = node;
    }

    function map(n: TNode):TOut {
        untyped {
            throw 0;
        }
    }

    public function hasNext():Bool {
        return switch node {
            case Some(_): true;
            case None: false;
        }
    }

    public function next():TOut {
        var res:TOut = map(node.getValue());
        node = (switch node {
            case Some(x): cast x.next;
            case None: None;
        });
        return res;
    }

    var node(default, null): Option<TNode>;
}

class NodeTreeNodeIterator<T, TNode:TreeNodeBase<T>> extends TreeNodeIterator<T, TNode, TNode> {
    override function map(n: TNode):TNode {
        return n;
    }
}

class MappedTreeNodeIterator<TIn, TOut, TNode:TreeNodeBase<TIn>> extends TreeNodeIterator<TIn, TOut, TNode> {
    public function new(node, f) {
        super(node);

        this.f = f;
    }

    override function map(n: TNode):TOut {
        return f( n );
    }

    var f(default, null): TNode->TOut;
}

