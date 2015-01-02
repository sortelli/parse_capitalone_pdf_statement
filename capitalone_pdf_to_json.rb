#!/usr/bin/env ruby

require "bundler/setup"
require_relative "parse_capitalone_pdf_statement"

unless ARGV.size == 1
  $stderr.puts "usage: #{File.basename(__FILE__)} statement.pdf"
  exit 1
end

pdf_path = ARGV.first

puts CapitalOneStatement.new(pdf_path).to_json
