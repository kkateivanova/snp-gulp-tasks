through2 = require 'through2'
libpath = require 'path'
helpers = require '../lib/helpers'
browserSync = require('browser-sync')
$ = helpers.gulpLoad [
  'if'
  'filter'
  'plumber'
  'sass'
  'resource'
  'sourcemaps'
  'postcss'
  'concat'
  'bless'
]

PROP = require '../lib/config'

module.exports = ->
  ext = PROP.path.styles('ext')
  filter_vendor = $.filter 'vendor.css', {restore: true}
  filter_scss = $.filter ['*.scss', '*.sass'], {restore: true}
  csswring = require 'csswring'
  autoprefixer = require 'autoprefixer'
  postcssUrl = require 'postcss-url'
  ORDER = []
  postprocessors = [
    autoprefixer browsers: [
      'last 222 version'
      'ie >= 8'
      'ff >= 17'
      'opera >=10'
    ]
  ]
  unless PROP.isDev
    postprocessors = postprocessors.concat [
      csswring
      postcssUrl({
        url: 'inline'
        maxSize: 12
      })
    ]

  gulp.src PROP.path.styles()
    .pipe $.if PROP.isNotify, $.plumber {errorHandler: helpers.errorHandler}
    .pipe filter_scss
    .pipe $.sass includePaths: [PROP.path.styles('path')]
    .pipe filter_scss.restore
    .pipe filter_vendor
    .pipe $.resource 'resources'
    .pipe filter_vendor.restore
    .pipe $.sourcemaps.init()
    .pipe $.postcss postprocessors
    .pipe through2.obj ((file, enc, cb)->
      ORDER.push file
      cb()
    ), (cb)->
      mainFile = null
      ORDER.forEach (file)=>
        if /main\.css$/.test file.path then mainFile = file
        else @push file
      @push mainFile if mainFile?
      cb()

    .pipe $.concat 'main.css'
    .pipe $.bless()
    .pipe browserSync.reload {stream: true}
    .pipe $.sourcemaps.write '.'
    .pipe gulp.dest PROP.path.styles 'dest'
    .pipe $.resource.download()
    .pipe gulp.dest PROP.path.build()
