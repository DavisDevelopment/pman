
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'
prompt = require 'prompt'

before = exports['before'] = (s, what) -> s[...s.indexOf(what)]
after = exports['after'] = (s, what) -> s[(s.indexOf(what) + what.length)...]
divide = exports['divide'] = (s, what) -> [before(s, what), after(s, what)]

promptBool = exports['promptBool'] = ([msg, def]..., callback) ->
    _cb = (error, result) ->
        if error?
            callback(error, false)
        else
            val = result.val.toLowerCase() == 'y'
            callback(null, val)

    prompt.start()
    prompt.get({
        properties: {
            val: {
                message: msg,
                default: if def then 'y' else 'n'
            }
        }
    }, _cb)

Build = exports['Build'] = class
    constructor: ->
        null

    execute: (callback) ->
        null

    confirm: (callback) ->
        _.defer(_.partial(callback, null, true))
