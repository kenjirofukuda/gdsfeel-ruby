#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl_token.rb'

module GPL
	
	class Parser
		TOKENIZERS = [CommentAndStringTokenizer, OperatorTokenizer]
		
		def tokens(token, file_context = false)
			@tokens = []
			tokenizer_class = TOKENIZERS[0]
			tokenize_tree(token, tokenizer_class)
			@tokens.flatten!
			@tokens
		end

		def self.debug_file(path)
			unresplved = {}
			#puts "###DEBUG### #{File.basename(path)}"
			File.open(path) { |fd|
				fd.each_line("\r") { |line|
					line.chomp!
					parser = self.new
					tokens = parser.tokens(line)
					puts "ORIG :{#{line}}"
					puts "AFTER:{#{tokens.inspect}}"
					puts "\n"
					tokens.each { |token|
						if token.kind == :UNRESOLVED
							unresplved[token.text] = 1
						end
					}
				}
			}
			puts "\n\n"
			p unresplved.keys.sort
		end

		##############
		private
		##############
		def self.next_tokenizer_class(tokenizer_class)
			ind = TOKENIZERS.index(tokenizer_class)
			return nil if ind.nil?
			TOKENIZERS[ind + 1]
		end
		
		def tokenize_tree(token, tokenizer_class)
			subtokens = []
			if token.kind_of?(String)
				split_text = token
			else
				return if token.resolved?
				split_text = token.text
			end
			return if tokenizer_class.nil?
			tokenizer = tokenizer_class.new(split_text)
			subtokens = tokenizer.tokens
			if @tokens.size == 0
				@tokens = subtokens
			end
			if token.kind_of?(Token)
				replace_index = @tokens.index(token)
				if replace_index.nil? 
					puts "### WARNIG ### Can't replace #{token.inspect}"
				else
					if subtokens.size > 0
						@tokens[replace_index] = subtokens
						@tokens.flatten!						
					end
				end
			end
			subtokens.each { |sub_token|
				tokenize_tree(sub_token, 
					Parser.next_tokenizer_class(tokenizer_class))
			}
		end	
		
	end # -- Parser
	
end # -- GPL

def module_test
	include GPL
	puts "test on: #{File.basename($0)}" 
GPL::Parser.debug_file(File.join(GPL::Constants::TOOL_PATH, GPLHelp::tool_filenames[1]))	
end

if $0 == __FILE__
	module_test
end