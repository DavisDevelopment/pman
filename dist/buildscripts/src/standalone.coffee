
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'
tools = require './tools'
prompt = require 'prompt'

packager = require 'electron-packager'

scriptdir = path.resolve(__dirname, '..')

options = exports['options'] = do ->
    defaltOptions =
      dir: scriptdir
      name: 'pman'
      arch: 'x64'
      version: '1.6.2'
      out: path.join(scriptdir, 'releases')
      'app-bundle-id': ''
      'app-version': ''
      overwrite: true
      asar: true
      prune: true
      icon: path.join(scriptdir, 'assets/icon32.png')
      app_version: '0.1.2'
      bundle_id: ''
      appname: 'pman'
      sourcedir: scriptdir
      ignore: path.join(scriptdir, 'releases')
    (o...) -> _.extend(_.clone(defaltOptions), o...)

# Build class
PackBuild = exports['PackBuild'] = class extends tools.Build
    constructor: (platform, arch='all', rest...) ->
        super()
        @options = options({
            platform: platform
            arch: arch
        }, rest...)

    execute: (callback) ->
        packager(@options, callback)

    confirm: (callback) ->
        tools.promptBool("package for #{@options.platform} #{@options.arch}?", no, callback)

