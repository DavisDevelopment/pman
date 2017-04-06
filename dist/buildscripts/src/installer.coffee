fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

tools = require './tools'
standalone = require './standalone'
{PackBuild} = require './standalone'

class InstallerBuild extends tools.Build
    constructor: (platform, arch) ->
        super()

        @options = {
            src: null
        }

    confirm: (callback) ->
        tools.promptBool("package for #{@options.platform} #{@options.arch}?", no, callback)
