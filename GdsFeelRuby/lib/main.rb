# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'gpl_data.rb'

puts "Hello World", RUBY_VERSION

%w(3.141592654 5 32767 32768 TRUE FALSE 1 0 1E8 .5 0. 0.00000000000001).each { |s|
  ds = GPL::ValueFactory.from_str(s)
  p [ s , ds, ds.attr]
}