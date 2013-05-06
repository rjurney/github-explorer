require 'rubygems'
require 'open-uri'
require 'zlib'
require 'yajl'
 
gz = open('http://data.githubarchive.org/2012-03-11-12.json.gz')
js = Zlib::GzipReader.new(gz).read
 
Yajl::Parser.parse(js) do |event|
  str = Yajl::Encoder.encode(event)
  puts str
end
