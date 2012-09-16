#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'number_eval'
require 'readline'

def readline2
  prompt = '? '
  printf "%s", prompt
  gets
end

include Readline
include GPL
lc = nil
while s = readline('? ', true)
  if s.downcase == "exit"
    break
  end
  if s.size == 0
    next
  end
  if /^\\/ =~ s and lc != nil
    call = Regexp.last_match.post_match
    if call == 'l'
      puts lc.methods
    else
      begin
        p lc.send(call)
      rescue
        puts "### DEBUG ### message not found #{call}"
      end
    end
  else
    lc = GPLLineContext.new(s)
    puts lc.debug_str
  end
end
puts
