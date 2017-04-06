
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
      overwrite: yes
      asar: no
      prune: yes
      icon: path.join(scriptdir, 'assets/icon32.png')
      app_version: '0.1.2'
      bundle_id: ''
      appname: 'pman'
      sourcedir: scriptdir
      ignore: path.join(scriptdir, 'releases')
    (o...) -> _.extend(_.clone(defaltOptions), o...)

exports['Pack'] = class Pack extends tools.Task
    constructor: (@platform, @arch='all', rest...) ->
        super()

        @promptMessage = "package as standalone application for #{@platform}/#{@arch}?"
        @promptDefault = yes
        
        @options = options({
            platform: @platform
            arch: @arch
        }, rest...)

    perform: ( cb ) ->
        packager(@options, cb)

exports['PackAll'] = class PackAll extends tools.Batch
    constructor: ->
        super()
        
        @tasks = [
            new Pack('linux', 'x64')
            new Pack('win32', 'x64')
        ]

        @promptMessage = "package app?"
        @promptDefault = yes
