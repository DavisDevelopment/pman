
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'
prompt = require 'prompt'

before = exports['before'] = (s, what) -> s[...s.indexOf(what)]
after = exports['after'] = (s, what) -> s[(s.indexOf(what) + what.length)...]
divide = exports['divide'] = (s, what) -> [before(s, what), after(s, what)]

prompt.start()
promptBool = exports['promptBool'] = ([msg, def]..., callback) ->
    console.log 'anus'
    _cb = (error, result) ->
        #prompt.stop()
        _.defer ->
            if error?
                callback(error, false)
            else
                val = result.val.toLowerCase() == 'y'
                callback(null, val)

    prompt.get({
        properties: {
            val: {
                message: msg,
                default: if def then 'y' else 'n'
            }
        }
    }, _cb)

exports['Build'] = class Build
    constructor: ->
        null

    execute: (callback) ->
        _.defer(_.partial(callback, null, null))

    confirm: ([msg, def=no]..., callback) ->
        promptBool msg, def, callback

exports['Builds'] = class Builds extends Build
    constructor: (@builds=[]) ->
        super()

    execute: ([flow=null]..., callback) ->
        if not flow?
            flow = async.series
        flow(Builds.execs( @builds ), callback)

    @execs: (list) -> (Builds.exec( build ) for build in list)
    @exec: (build) ->
        (callback) ->
            build.execute(callback)

exports['Task'] = class Task extends Build
    constructor: ->
        @promptMessage = 'perform this task?'
        @promptDefault = no
        @promptResult = null

    perform: (callback) ->
        super( callback )

    confirm: ( cb ) ->
        if not @promptResult?
            callback = (error, value) =>
                if error?
                    cb(error, null)
                else
                    @promptResult = value
                    cb(error, value)
            super(@promptMessage, @promptDefault, callback)
        else
            _.defer(_.partial(cb, null, @promptResult))

    execute: ( cb ) ->
        @confirm (error, perform) =>
            if error?
                cb error, null
            else if perform
                @perform cb
            else
                cb(null, null)

exports['Batch'] = class Batch extends Task
    constructor: (tasks=[]) ->
        super()
        @tasks = tasks

    perform: ( cb ) ->
        self = this
        conf = (t)->(f)->t.confirm(f)
        perf = (t)->(f)->t.execute(f)

        confs = (conf( t ) for t in @tasks)
        perfs = (perf( t ) for t in @tasks)

        async.series confs, (err, vals) ->
            async.series perfs, cb

# Path related stuff
scriptdir = exports['scriptdir'] = (stuff...) ->
    return path.resolve(__dirname, '..', stuff...)
