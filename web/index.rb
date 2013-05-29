# myapp.rb
require 'sinatra'

class HelloWorld < Sinatra::Base
  
  set :root, File.dirname(__FILE__)
  
  get '/' do
    'Hello world!'
  end
end