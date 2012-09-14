#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl.rb'

module GPL

	class Reader
		attr_reader :gets
		attr_reader :getc
		attr_reader :ungetc
		# attr_reader :eof?
		# NOTE: why can't use '?' this version of ruby
		#ruby 1.8.6 (2007-09-24 patchlevel 111) [i486-linux]
		attr_reader :is_eof
		attr_reader :rewind
	end
	
	class StringReader < Reader
		def initialize(text)
			@text = text
			@pos = 0
		end
		
		def rewind
			@pos = 0			
		end
		
		def getc
			ch = @text[@pos]
			@pos += 1
			ch
		end
		
		def ungetc(num)
			@pos -= num
			if @pos < 0
				@pos = 0
			end
			nil
		end
		
		def all
			@text
		end
		
		def gets
			return nil if is_eof 
			s = @text[@pos, @text.size]
			@pos += s.size
			s
		end
		
		def is_eof
			@text[@pos] == nil
		end
		
	end
	
	
	class ReadlineReader < Reader
		require 'readline'
		include Readline

		attr :prompt
		attr_reader :pos
		attr_reader :lines
		
		def initialize
			@lines = []
			@line_count = 0
			@prompt = '? '
			rewind
		end

		def rewind
			@pos = 0			
			@eof = false
		end
		

		def all
			@lines.join
		end

		def list
			puts all
		end

		def gets
			l = get_buffer
			if l != nil
				@pos += l.size
			else
				@eof = true	
			end
			l
		end

		def getc
			if all[@pos] == nil
				get_buffer
			end
			ch = all[@pos]
			@pos += 1
		end

		def ungetc(num)
			@pos -= num
			nil
		end

		def is_eof
			@eof
		end
		
		#########
		private
		#########
		
		def get_buffer
			l = readline(@prompt, true)
			if l != nil
				l += "\n"
				@lines.push(l)
			end
			l
		end
	end
	
end
