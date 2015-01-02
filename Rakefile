require 'bundler'
Bundler.setup(:development)
require 'yard'

YARD::Rake::YardocTask.new do |config|
  config.files   = ['./lib/**/*.rb']
  config.options = [
    '--no-private',
    '--output-dir', 'docs'
  ]
end
