#!/usr/bin/env ruby

require 'pdf-reader'

reader = PDF::Reader.new(ARGV[0])
reader.pages.each_with_index do |page, index|
  puts "Page number: #{index + 1}"
  puts page.text.split("\n").map {|line| '  %s' % line}
end
