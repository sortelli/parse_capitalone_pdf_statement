# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parse_capitalone_pdf_statement/version'

Gem::Specification.new do |spec|
  spec.name          = "parse_capitalone_pdf_statement"
  spec.version       = CapitalOneStatement::VERSION
  spec.authors       = ["Joe Sortelli"]
  spec.email         = ["joe@sortelli.com"]
  spec.summary       = "Parse a Capital One PDF statement file into structured data"
  spec.description   = %q{
    The Capital One website only provides a way to download structured
    data of credit card transaction history for the previous 180
    days. However, you are able to download monthly PDF account
    statements for the previous few years.  This library allows you
    to parse a Capital One PDF monthly statement, and access
    structured transaction history data.
  }
  spec.homepage      = "https://github.com/sortelli/parse_capitalone_pdf_statement"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pdf-reader"
  spec.add_dependency "json"

  spec.add_development_dependency "yard"
end
