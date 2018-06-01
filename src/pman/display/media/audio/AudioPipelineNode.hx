package pman.display.media.audio;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.AudioNode;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;

import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.html.JSTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;

/*
   class used to represent a 'node' in the 'audio pipeline' 
   as the name implies
*/
class AudioPipelineNode {
    /* Constructor Function */
    public function new(pipeline: AudioPipeline) {
        this.iNode = null;
        this.oNode = null;
        this.pipeline = pipeline;
        this.nextNode = null;

        connections = new NodeConnectionManifest();
    }

/* === Instance Methods === */

    /**
      * connect [this] node to the next one in the pipeline
      */
    public function connect(nextNode: AudioPipelineNode):Void {
        if (numberOfOutputs == 0 || nextNode.numberOfInputs == 0) {
            throw 'Error: Data-flow between these two nodes is impossible';
        }

        // obtain references to relevant AudioNode instances
        var i = nextNode.input(), o = output();
        switch [i, o] {
            case [null, _]:
                throw 'CannotConnect: AudioPipelineNode did not provide an input';
            case [_, null]:
                throw 'CannotConnect: AudioPipelineNode did not provide an output';
            case [_, _]:
                if (numberOfOutputs == 1) 
                    o.connect(i);
                else 
                    for (index in 0...numberOfOutputs)
                        o.connect(i, [index]);
            default:
                throw 'Wtf';
        }

        /*
        if (i == null) {
            throw 'CannotConnect: AudioPipelineNode did not provide an input';
        }
        else if (o == null) {
            throw 'CannotConnect: AudioPipelineNode did not provide an output';
        }

        if (numberOfOutputs == 1) {
            oNode.connect( nextNode.iNode );
        }
        else {
            for (i in 0...numberOfOutputs) {
                oNode.connect(nextNode.iNode, [i]);
            }
        }
        */

        //
        _afterConnect( nextNode );
    }

    /**
      * disconnect [this] Node
      */
    public function disconnect():Void {
        if (!childNodes.empty()) {
            for (node in childNodes) {
                node.disconnect();
            }
        }
        else {
            //iNode.disconnect();
            //oNode.disconnect();
            qm(iNode, _.disconnect());
            qm(oNode, _.disconnect());
        }
    }

    /**
      completely disassemble [this]'s connection hierarchy
     **/
    public function reflow():Void {
        disconnect();
        connectOwnChildren();

        if (prevNode != null) {
            connectNodes(prevNode, this);
        }

        if (nextNode != null) {
            connectNodes(this, nextNode);
        }
    }

    /**
      internal method used to somehow connect [this] Node's children to one another
      --
      default implementation chains them together in the order in which they occur in [childNodes]
     **/
    function connectOwnChildren() {
        if (!childNodes.empty()) {
            var i = 0, node;
            while (i < childNodes.length) {
                node = childNodes[i++];
                if (childNodes[i] != null) {
                    connectNodes(node, childNodes[i]);
                }
            }
        }
    }

    /**
      * initialize [this] node
      */
    public function init():Void {
        this._initted = true;
    }

    public inline function isInitted():Bool {
        return _initted;
    }

    /**
      internal method called after a connection is made
     **/
    function _afterConnect(nextNode: AudioPipelineNode) {
        //
    }

    public function appendChild(node: AudioPipelineNode) {
        qm(childNodes, _ = []);
        if (childNodes.has( node )) {
            throw 'Error: Cannot insert a single node into the pipeline multiple times';
        }

        var tmp = childNodes[childNodes.length - 1];
        childNodes.push( node );
        if (tmp != null) {
            connectNodes(tmp, node);
        }
    }

    public function prependChild(node: AudioPipelineNode) {
        qm(childNodes, _ = []);
        if (childNodes.has( node )) {
            throw 'Error: Cannot insert a single node into the pipeline multiple times';
        }

        var tmp = childNodes[0];
        childNodes.unshift( node );
        if (tmp != null) {
            connectNodes(node, tmp);
        }
    }

    public function removeChild(node: AudioPipelineNode):Bool {
        //TODO
        throw 'Not yet implemented';
    }

    /**
      * connect two nodes
      */
    static inline function connectNodes(a:AudioPipelineNode, b:AudioPipelineNode):Void {
        if (!a.isInitted()) {
            a.init();
        }

        if (!b.isInitted()) {
            b.init();
        }

        a.connect( b );
        a.setNextNode( b );
    }

    /**
      * set [this]'s node
      */
    public inline function setNode(i:Null<AudioNode<NativeAudioNode>>, ?o:Null<AudioNode<NativeAudioNode>>):Void {
        if (o == null) {
            o = i;
        }

        iNode = i;
        oNode = o;
    }

    public inline function setNextNode(node: Null<AudioPipelineNode>):Void {
        this.nextNode = node;

        if (node != null)
            node.prevNode = this;
    }

    public inline function setPrevNode(node: Null<AudioPipelineNode>):Void {
        this.prevNode = node;

        if (node != null) {
            node.nextNode = this;
        }
    }

    /**
      get the input node for [this] Node
     **/
    public function input():Null<DNode> {
        if (!childNodes.empty()) {
            return childNodes[0].input();
        }
        else {
            return iNode;
        }
    }

    /**
      get the output node for [this] Node
     **/
    public function output():Null<DNode> {
        return (!childNodes.empty() ? childNodes[childNodes.length - 1].output() : oNode);
    }

/* === Computed Instance Fields === */

    public var numberOfInputs(get, never):Int;
    private inline function get_numberOfInputs() return (iNode != null ? iNode.numberOfInputs : 0);

    public var numberOfOutputs(get, never):Int;
    private inline function get_numberOfOutputs() return (oNode != null ? oNode.numberOfOutputs : 0);

/* === Instance Fields === */

    public var childNodes: Null<Array<AudioPipelineNode>>;
    var iNode: Null<AudioNode<NativeAudioNode>>;
    var oNode: Null<AudioNode<NativeAudioNode>>;
    var connections: NodeConnectionManifest;

    public var pipeline: AudioPipeline;
    public var nextNode(default, null): Null<AudioPipelineNode>;
    public var prevNode(default, null): Null<AudioPipelineNode>;

    private var _initted:Bool = false;
}

/**
  purpose of class
 **/
class NodeConnectionManifest {
    /* Constructor Function */
    public function new() {
        input = new Array();
        output = new Array();
    }

/* === Instance Methods === */

    public function mkIn(node:DNode, ?i:Int, ?o:Int) {
        input.push(new NodeConnection(node, i, o));
    }

    public function mkOut(node:DNode, ?i:Int, ?o:Int) {
        output.push(new NodeConnection(node, i, o));
    }

    public function clear() {
        input.iter.fn(_.dispose());
        output.iter.fn(_.dispose());
        input = new Array();
        output = new Array();
    }

/* === Instance Fields === */

    public var input(default, null): Array<NodeConnection>;
    public var output(default, null): Array<NodeConnection>;
}

@:structInit
class NodeConnection {
    /* Constructor Function */
    public function new(node:DNode, ?outputIndex:Int, ?inputIndex:Int):Void {
        this.node = node;
        this.outputIndex = outputIndex;
        this.inputIndex = inputIndex;
    }

/* === Instance Methods === */

    public inline function dispose() {
        node = null;
        outputIndex = null;
        inputIndex = null;
    }

    public inline function hasIndices():Bool {
        return (outputIndex != null || inputIndex != null);
    }

    public function indexPair():Array<Int> {
        return 
            if (outputIndex != null)
                if (inputIndex != null)
                    [outputIndex, inputIndex];
                else
                    [outputIndex];
            else
                [];
        //node.channelCount
    }

/* === Instance Fields === */

    public var node: DNode;
    @:optional public var outputIndex:Int;
    @:optional public var inputIndex: Int;
}

typedef NativeAudioNode = js.html.audio.AudioNode;
typedef ANode<T:NativeAudioNode> = AudioNode<T>;
typedef DNode = ANode<NativeAudioNode>;
