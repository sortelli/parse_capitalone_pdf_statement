require 'bundler'
Bundler.setup(:development)
require 'yard'

YARD::Rake::YardocTask.new do |config|
  config.files   = ['./parse_capitalone_pdf_statement.rb']
  config.options = [
    '--no-private',
    '--output-dir', 'docs'
  ]
end
