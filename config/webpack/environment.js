const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')
const webpack = require('webpack')

environment.plugins.append('Provide',
  new webpack.ProvidePlugin({
    moment: 'moment',
    _: 'underscore',
    Routes: 'routes',
    Popper: ['popper.js', 'default']
  })
)

const custom = {
  resolve: {
    alias: {
      jquery: 'jquery/src/jquery',
    }
  }
}

environment.config.merge(custom)
environment.loaders.prepend('erb', erb)
module.exports = environment

