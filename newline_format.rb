#!/usr/bin/env ruby

require 'rubygems'
require 'zlib'
require 'yajl'
 
Dir.glob('data/*.json.gz').each do |f|
  gz = open(f)
  js = Zlib::GzipReader.new(gz).read
 
  Yajl::Parser.parse(js) do |event|
    puts Yajl::Encoder.encode(event)
  end
end