
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

packager = require 'electron-packager'
deb_installer = require 'electron-installer-debian'

scriptdir = (__dirname + '')

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

options = (o...) -> _.extend(_.clone(defaltOptions), o...)

# task registry
actions = {}

# Package PMan for Linux and Windows
build_releases = actions['pack'] = ( complete ) ->
    complete ?= (-> null)
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
            console.log ' -- PMan Packaged for Linux and Windows -- '
        do complete

# Build the .deb installer
build_debian_installer = actions['deb'] = actions['debian'] = ( complete ) ->
    complete ?= (-> null)
    release_dir = path.join(scriptdir, 'releases', 'pman-linux-x64')
    installers_dir = path.join(scriptdir, 'installers')
    
    options =
        src  : release_dir
        dest : installers_dir
        arch : 'x64'

    #deb_installer callback
    dicb = (error) ->
        if error?
            console.error( error )
        else
            console.log " -- Created Debian Installer for PMan -- "
            do complete

    deb_installer(options, dicb)

# 'main' function
do ->
    # get parameters
    actionNames = process.argv[2..]
    tasks = do ->
        for name in actionNames
            if name of actions
                actions[name]
    
    taskCallback = (error) ->
        if error?
            console.error error

    async.series tasks, taskCallback

