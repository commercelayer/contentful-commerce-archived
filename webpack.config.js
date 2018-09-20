const path = require('path')

module.exports = {
  mode: 'production',
  entry: './index.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, "assets/javascripts")
  }
}
