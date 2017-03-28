
fs = require 'fs'
path = require 'path'

async = require 'async'
_ = require 'underscore'

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
Build = exports['Build'] = class
    constructor: (platform, arch='all', rest...) ->
        @options = options({
            platform: platform
            arch: arch
        }, rest...)

    build: (callback) ->
        packager(@options, callback)

    @buildAll: (builds, callback) ->
        flist = (b.build.bind( b ) for b in builds)
        async.series(flist, callback)

