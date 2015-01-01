#!/usr/bin/env ruby

require 'pdf-reader'

def parse_transaction(line)
  regex = /^(\d+) +(\d\d) ([A-Z][A-Z][A-Z]) (.+[^ ]) +(\(?\$[0-9,.]+\)?) *$/
  return nil unless line =~ regex

  {
    :number => $1,
    :day    => $2,
    :month  => $3,
    :desc   => $4,
    :amount => $5
  }
end

reader = PDF::Reader.new(ARGV[0])
reader.pages.each_with_index do |page, page_num|
  puts "Page number: #{page_num + 1}"

  page.text.split("\n").each do |line|
    strs = if page_num == 0
      [line[5, 72]]
    else
      [line[0, 72], line[82..-1]]
    end

    data = strs.map {|str| parse_transaction(str)}.compact

    data.each {|d| p d}
  end
end
