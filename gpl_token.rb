#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl.rb'
require 'gpl_data.rb'
require 'gpl_reader.rb'
require 'gpl_help.rb'

module GPL

  $using_space = true
  
  class ParseError < StandardError
  end

  class Token
    attr :text
    attr :kind, true

    def initialize(text)
      @text = text
      @kind = :UNRESOLVED
    end

    def inspect
      sprintf "#<:%s '%s'>", kind, text
    end
    
    def resolved?
      kind != :UNRESOLVED 
    end
    
  end # -- Token

  class Tokenizer
    def initialize(text, reader = nil)
      @text = text      
      @reader = reader.nil? ? StringReader.new(text)  : reader      
      @tokens = nil
      @word = ''
      reset_state
    end

    def reset_state
      @in_number = false
      @in_comment = false
      @in_string = false
    end
    
    def push_token(kind = nil)
      if kind != nil 
        unless kind.kind_of?(Symbol)
          raise ArgumentError.new("token kind must be Symbol")
        end
      end
      non_zero = @word
      unless $using_space
        non_zero = @word.strip
      end
      if non_zero.size > 0
        t = Token.new(non_zero)
        t.kind = kind unless kind.nil?
        @tokens.push(t)
      end
      @word = ''
    end
    
    def tokens
      if @tokens.nil? 
        @reader.rewind
        @tokens = []
        reset_state
        run_tokenizer
        mark_tokens
      end
      @tokens
    end
    
    def resolved?
      unresolved_tokens.size == 0
    end
    
    def unresolved_tokens
      @tokens.select { |t| t.kind == :UNRESOLVED}
    end
    

    #######
    protected
    ########
    def run_tokenizer
      puts "WARNING not call"
    end
    
    def mark_tokens()
    end
    
    def is_space(ascii)
      ascii.chr == ' ' or ascii.chr == "\t"
    end
    
    def skip_spaces(ch)
      push_token
      if $using_space
        @word << ch.chr
      end
      while (ch3 = @reader.getc) != nil
        if not is_space(ch3)
          @reader.ungetc(1)
          break
        end        
        if $using_space
          @word << ch3.chr
        end
      end
      if $using_space
        push_token(:SPACES)
      end
    end
  
    # false if ending character ch not found 
    def collect_until(ch)
      #until @reader.eof?
      until @reader.is_eof
        next_ch = @reader.getc
        @word << next_ch
        if next_ch == ch
          return true
        end
      end
      return false
    end

  end # -- Tokenizer

  class CommentAndStringTokenizer < Tokenizer
    
    def handle_single_comment(ch)
      return if @in_string
      @in_comment = true
      push_token
      @word << ch
      rest = @reader.gets
      @word << rest unless rest.nil?
      push_token(:COMMENT)
    end

    def handle_string(ch)
      return if @in_comment or @in_string
      push_token
      @in_string = true
      @word << ch
      ok = collect_until(?")
      if @word.size >= 2
        if ok
          push_token(:STRING)
          @in_string = false
        else
          @reader.ungetc(@word.size - 1)
          raise ParseError.new("string not closed")
        end
      end
    end
    
    def handle_quote_comment(ch)
      return if @in_comment or @in_string
      push_token
      @in_comment = true
      @word << ch
      ok = collect_until(?')
      if @word.size >= 2
        if ok
          push_token(:COMMENT)
          @in_comment = false
        else
          @reader.ungetc(@word.size - 1)
          raise ParseError.new("comment not closed")
        end
      end
    end
    
    def run_tokenizer
      @word = ''
      #return @tokens if @reader.eof?
      return @tokens if @reader.is_eof
      begin
        ch = @reader.getc
        break if ch.nil?
        case ch
        when ?|
          handle_single_comment(ch)
        when ?"
          handle_string(ch)
        when ?`
          handle_quote_comment(ch)
        else
          @word << ch
        end
      #end until @reader.eof?
      end until @reader.is_eof
      push_token
    end
  end
  
  class OperatorTokenizer < Tokenizer
    TOKEN_DELIMS = '-+*/:;=()^%!<>,|[]'.split(//)
    DOUBLE_KEYS = [':=', '<>', '>=', '<=']
    DOUBLE_KEYS_FIRST_CHARS = DOUBLE_KEYS.collect { |dc| dc[0...1] }.uniq

    def handle_namespace(ch)
      return if (@in_comment or @in_string)
      @word << ch.chr
      re = /[\$#_A-Z0-9]/
      no_use_next_chr = false
      while (ch2 = @reader.getc)
        unless re =~ ch2.chr
          no_use_next_chr = true
          break
        end
        @word << ch2.chr
        #break if @reader.eof?
        break if @reader.is_eof
      end
      push_token
      if no_use_next_chr
        @reader.ungetc(1)
      end
    end

    def handle_number(ch)
      if @word.size > 0 and @word[-1] == ?-
        
      else
        push_token
      end
      @word << ch.chr
      re_str = '[-+.0-9e]'
      re = Regexp.new(re_str)
      no_use_next_ch = false
      while (ch2 = @reader.getc)
        unless re =~ ch2.chr
          no_use_next_ch = true
          break
        end
        if ch2 == ?- or ch2 == ?+
          if /[0-9]/ =~ @word[-1].chr
            no_use_next_ch = true
            break
          end  
        end
        @word << ch2.chr
        #break if @reader.eof?
        break if @reader.is_eof
      end
      if GPL::GPLNumber.ok_str?(@word)
        push_token(:NUMBER)
      else
        push_token(:ERROR_NUMBER)
      end
      if no_use_next_ch
        @reader.ungetc(1)
      end
    end
    
    def handle_nonword_characters(ch)
      push_token
      @word << ch.chr
      next_ch  = @reader.getc
      return if next_ch.nil?
      no_use_next = true
      if DOUBLE_KEYS_FIRST_CHARS.include?(ch.chr)
        if DOUBLE_KEYS.include?(ch.chr + next_ch.chr)
          @word << next_ch.chr
          no_use_next = false
        end
        push_token(:OPERATOR)
      elsif ch.chr == '+' or ch.chr == '-'
        if is_space(next_ch)
          push_token(:OPERATOR_DIADIC)
        elsif ch.chr == '-' and /[.0-9]/ =~ next_ch.chr
        else
          push_token(:OPERATOR_MONADIC)
        end
      else
        push_token(GPL.operator?(@word) ? :OPERATOR : :UNRESOLVED)
      end
      if no_use_next
        @reader.ungetc(1)
      end
    end
    
    def run_tokenizer
      begin
        ch = @reader.getc
        break if ch.nil?
        if /[A-Z]/ =~ ch.chr
          handle_namespace(ch)
        elsif /[.0-9]/ =~ ch.chr
          handle_number(ch)
        elsif TOKEN_DELIMS.include?(ch.chr)
          handle_nonword_characters(ch)
        elsif is_space(ch)
          skip_spaces(ch)
        else
          @word << ch.chr
        end
      #end until @reader.eof?
      end until @reader.is_eof
      #puts "DEBUG: last push is '#{@word}'"
      push_token
    end

    def mark_tokens()
      unresolved_tokens.each { |token|
        if GPL.functions_only.include?(token.text)
          token.kind = :OPERATOR_FUNCTION        
        elsif GPL.commands_only.include?(token.text)
          token.kind = :OPERATOR_COMMAND
        elsif GPL.commands_and_functions.include?(token.text)
          token.kind = :OPERATOR_BOTH
        elsif GPL.operator?(token.text)
          token.kind = :OPERATOR
        elsif GPL.flow?(token.text)
          token.kind = :FLOW
        elsif GPL.known_symbol?(token.text)
          token.kind = :KEYWORD
        end
      }
    end
    
  end # -- OperatorSpliter
    
end # -- GPL

def module_test
  puts "module test on #{File.basename($0)}"
end

if $0 == __FILE__
  module_test
end
