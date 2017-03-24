
fs = require 'fs'
path = require 'path'

packager = require 'electron-packager'
async = require 'async'
_ = require 'underscore'

scriptdir = (__dirname + '')

defaltOptions =
  dir: scriptdir
  name: 'pman'
  #platform: 'linux'
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

options = (o...) -> _.extend(_.clone(defaltOptions), o...)

do ->
    builds = []
    #pack_cb = ((error, appPaths) -> if error? then console.error(error) else console.log(appPaths))
    #pack_task = (settings) -> return _.bind(packager, options(settings))
    pack_task = (o) -> (cb) -> packager(options( o ), cb)
    plan = (settings) ->
        builds.push pack_task( settings )

    # Linux Build
    plan
        platform: 'linux'

    # Window Build
    plan
        platform: 'win32'
        arch: 'ia32'

    async.series builds, (error, paths) ->
        if error?
            console.error error
        else
            console.log _.flatten paths

    console.log " -- Done -- "
