package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;

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

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

/*
   class used to represent the flow of audio data through a pipeline
*/
class AudioPipeline {
    /* Constructor Function */
    public function new(renderer : LocalMediaObjectRenderer<MediaObject>):Void {
        this.renderer = renderer;
        active = false;
        treeBuilders = new Array();
        nodeList = new Array();
    }

/* === Instance Methods === */

    /**
      * Activate [this]
      */
    public function activate(?done : Void->Void):Void {
        if ( !active ) {
            buildit(function() {
                active = true;
                if (done != null)
                    done();
            });
        }
        else if (done != null) {
            done();
        }
    }

    /**
      * Deactivate [this]
      */
    public function deactivate(?done : Void->Void):Void {
        if ( !_closing ) {
            _closing = true;
            try {
                if (context != null) {
                    context.close(function() {
                        active = false;
                        _closing = false;
                        context = null;
                        source.disconnect();
                        source = null;
                        destination = null;
                        if (done != null)
                            defer( done );
                    });
                }
                else {
                    defer(function() if (done != null) done());
                }
            }
            catch (error : Dynamic) {
                defer(function() if (done != null) done());
            }
        }
    }

    /**
      * build out the AudioNode tree
      */
    @:access( pman.display.media.LocalMediaObjectRenderer )
    public function buildTree(done : Void->Void):Void {
        var prepare = ((context != null) ? context.close : defer);
        prepare(function() {
            context = new AudioContext();
            source = context.createSource(untyped renderer.mediaObject);
            destination = context.destination;

            source.connect( destination );

            for (f in treeBuilders) {
                f( this );
            }

            defer( done );
        });
    }

    /**
      * build out the node list
      */
    public function buildit(done: Void->Void):Void {
        var prepare = ((context != null) ? context.close : defer);
        prepare(function() {
            context = new AudioContext();
            source = context.createSource(untyped renderer.mediaObject);
            destination = context.destination;

            srcNode = new SourceAudioPipelineNode( this );
            srcNode.init();
            destNode = new DestAudioPipelineNode( this );
            destNode.init();
            currentNode = srcNode;

            for (node in nodeList) {
                node.init();

                connectNodes(currentNode, node);
                currentNode = node;
            }

            connectNodes(currentNode, destNode);

            defer( done );
        });
    }

    /**
      * rebuild the tree
      */
    public function rebuildTree(done : Void->Void):Void {
        deactivate(function() {
            activate( done );
        });
    }

    /**
      * create and return a new AudioPipelineNode
      */
    public inline function createNode(options: FAPDef):FunctionalAudioPipelineNode {
        return new FunctionalAudioPipelineNode(this, options);
    }

    /**
      * append a node to [this] pipeline
      */
    public function appendNode(node: AudioPipelineNode):Void {
        var tmp = destNode.prevNode;
        if (tmp == null) {
            throw 'Error: No node to attach to';
        }

        connectNodes(tmp, node);
        connectNodes(node, destNode);
        currentNode = node;
    }

    /**
      * prepend a node to [this] pipeline
      */
    public function prependNode(node: AudioPipelineNode):Void {
        if (srcNode == null) {
            throw 'Error: No node to attach to';
        }

        var tmp = srcNode.nextNode;
        connectNodes(srcNode, node);
        if (tmp != null) {
            connectNodes(node, tmp);
        }
    }

    /**
      * connect two nodes
      */
    public inline function connectNodes(a:AudioPipelineNode, b:AudioPipelineNode):Void {
        if (!a.isInitted()) {
            a.init();
        }

        if (!b.isInitted()) {
            b.init();
        }

        a.connect( b );
        a.setNextNode( b );
    }

/* === Instance Fields === */

    public var renderer : LocalMediaObjectRenderer<MediaObject>;
    public var context : AudioContext;
    public var source : AudioSource;
    public var destination : AudioDestination;
    public var srcNode: SourceAudioPipelineNode;
    public var destNode: DestAudioPipelineNode;

    public var active(default, null):Bool;

    //public var treeBuilders : Array<AudioManager->AudioPipelineNode->AudioPipelineNode>;
    public var treeBuilders: Array<AudioPipeline->Void>;

    private var nodeList: Array<AudioPipelineNode>;
    private var currentNode: Null<AudioPipelineNode> = null;
    private var _closing : Bool = false;
}

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
    }

/* === Instance Methods === */

    /**
      * connect [this] node to the next one in the pipeline
      */
    public function connect(nextNode: AudioPipelineNode):Void {
        if (numberOfOutputs == 0 || nextNode.numberOfInputs == 0) {
            throw 'Error: Data-flow between these two nodes is impossible';
        }

        if (numberOfOutputs == 1) {
            oNode.connect( nextNode.iNode );
        }
        else {
            for (i in 0...numberOfOutputs) {
                oNode.connect(nextNode.iNode, [i]);
            }
        }
    }

    /**
      * initialize [this] node
      */
    public function init():Void {
        this._initted = true;
    }

    public inline function isInitted():Bool return _initted;

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

/* === Computed Instance Fields === */

    public var numberOfInputs(get, never):Int;
    private inline function get_numberOfInputs() return (iNode != null ? iNode.numberOfInputs : 0);

    public var numberOfOutputs(get, never):Int;
    private inline function get_numberOfOutputs() return (oNode != null ? oNode.numberOfOutputs : 0);

/* === Instance Fields === */

    public var iNode: Null<AudioNode<NativeAudioNode>>;
    public var oNode: Null<AudioNode<NativeAudioNode>>;
    public var pipeline: AudioPipeline;
    public var nextNode(default, null): Null<AudioPipelineNode>;
    public var prevNode(default, null): Null<AudioPipelineNode>;

    private var _initted:Bool = false;
}

/*
   class used to represent an AudioPipelineNode that was created functionally
*/
class FunctionalAudioPipelineNode extends AudioPipelineNode {
    /* Constructor Function */
    public function new(pipeline:AudioPipeline, def:FAPDef):Void {
        super( pipeline );

        d = def;
    }

/* === Instance Methods === */

    override function connect(nextNode:AudioPipelineNode):Void {
        if (d.connect != null) {
            d.connect(this, nextNode);
        }
        else {
            super.connect( nextNode );
        }
    }

    override function init():Void {
        if (d.init != null) {
            d.init( this );
        }
        super.init();
    }

/* === Instance Fields === */

    public var d:FAPDef;
}

typedef FAPDef = {
    ?connect: FunctionalAudioPipelineNode->AudioPipelineNode->Void,
    ?init: FunctionalAudioPipelineNode->Void
};

class SourceAudioPipelineNode extends AudioPipelineNode {
    override function init():Void {
        setNode(null, cast pipeline.source);
    }
}

class DestAudioPipelineNode extends AudioPipelineNode {
    override function init():Void {
        setNode(cast pipeline.destination);
    }
}

typedef NativeAudioNode = js.html.audio.AudioNode;
typedef Fapn = FunctionalAudioPipelineNode;
