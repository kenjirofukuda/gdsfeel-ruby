#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl.rb'
require 'gpl_data.rb'
require 'cgi'


class Range 
  def length
    (last - first + (exclude_end? ? 0 : 1))
  end

  def as_offset_length
    [first, length]
  end
end

def category_of(s)
  type = :NIL
  if GPLNumber.ok_str?(s) 
    type = :NUMBER
  elsif all_op_keys.include?(s)
    type = :KEYWORD
  elsif /^".*"$/ =~ s
    type = :STRING
  else
    case s
      when '+', '-', '*', '/', '%'
        type = :ALITHMETIC_OPERATOR
      when '=', '<>', '>=', '<=', '<', '>'
        type = :BOOLEAN_OPERATOR
      when ':='
        type = :ASSIGN_OPERATOR
      when ','
        type = :ARRAY_CONNCAT_OPERATOR
      when '^'
        type = :ESCAPE_OPERATOR
      when '(', ')'
        type = :EVAL_SCOPE_OPERATOR
      when '[', ']'
        type = :ELEMENT_AT_OPERATOR
    end
  end
end

module GPL

  class GPLFlow
    @tokens
    def initialize(tokens)
      @tokens = tokens
    end
    def syntax_valid?
      false
    end
    def terminater_given?
      false
    end
  end

  class GPLFlowValueAssign < GPLFlow
  end

  class GPLProgram < GPLFlow
  end

  class GPLFlowIf < GPLFlow
    def syntax_valid?
      @tokens[-1] == 'THEN' or @tokens[-1] == 'ENDIF'
    end
    def terminater_given?
      @tokens[-1] == 'THEN'
    end
  end

  class GPLFlowLoop < GPLFlow
  end

  class GPLFlowSwitch < GPLFlow
  end

  class GPLFlowFactory
    CLASS_MAP = {
      'IF' => GPLFlowIf,
      'DO' => GPLFlowLoop,
    }

    def self.create(tokens)
      cls = CLASS_MAP[tokens[0]]
      cls.new(tokens)
    end
  end

  class GPLValueFactory
    def self.from_str(str)
      v = nil
      if GPLInteger.ok_str?(str)
        GPLInteger.new            
      end
      v
    end
  end

  class GPLOperator
    METHOD_TYPES = [ :DYADIC, :MONADIC, :NILADIC ]
    @name = ''
    @has_return_value = true  
    @argument_type = :NILADIC
    @left = nil
    @right = nil
    attr_accessor :name, :argument_type, :left, :right

    def set_argument(args)
      must_be_count = -1
      case @argument_type
        when :NILADIC
          must_be_count = 0
        when :DYADIC
          must_be_count = 2
        when :MONADIC
          must_be_count = 1
      end
      if args.size != must_be_count
        $stderr.puts "Argument Count Err"
        return
      end
      if args.size >= 1
        @left = args[0]
      end
      if args.size >= 2
        @right = args[1]
      end
    end

    def self.named(name)
      op = GPLOperator.new
      op.name = name
      op
    end

    def self.dyadic_named(name)
      op = named(name)
      op.argument_type = :DYADIC
    end

    def self.niladic_named(name)
      op = named(name)
      op.argument_type = :DYADIC
    end

    def self.monadic_named(name)
      op = named(name)
      op.argument_type = :DYADIC
    end

    def self.initialize
      assigin = dyadic_named(':=')  
    end
  end

  GPLOperator.initialize

  class GPLCommand < GPLOperator
    @@commands = {}
    def evalute
    end

    def self.register_command(clsname)
      cmd = eval(clsname).new
      @@commands[cmd.name.upcase] = cmd
    end

    def self.commands
      @@commands.keys
    end

    def self.builtin?(cmdname)
      commands.include?(cmdname.upcase)
    end

    def self.named(cmdname)
      if not builtin?(cmdname)
        return nil
      end
      @@commands[cmdname.upcase]
    end

    def self.initialize
      register_command('GPLCommand_Vars')
    end
  end

  class GPLCommand_Vars < GPLCommand
    def initialize
      @name = 'VARS'
    end

    def return_value
      ['SAMPLE', 'COMMANDS', 'HEAR']
    end
    def evalute
      puts return_value
    end
  end

  GPLCommand.initialize

  class GPLItem
  end

  class GPLWorkArea
    @@work_area = nil
    @vars = {}
    @subs = {}
    def add_var(var_name, var_value)
      @vars[var_name] = var_value
    end
    def vars
    end
    def subs
    end
    def clear
      @vars = {}
      @subs = {}
    end

    def self.default
      if @@work_area == nil
        @@work_area = GPLWorkArea.new
      end
      @@work_area
    end
  end


  def evalute(s)
    if (/([\w]+)\s?:=\s?(.+)/ =~ s) 
      var_name = $1  
      if GPLCommand.builtin?(var_name)
        $stderr.puts "Can't Assign: #{var_name} becores builtin function"
        return ""
      end
      value_exp = $2
      value = evalute($2)
      return ""
    end

    tokens = s.split(' ')
    if GPLCommand.builtin?(tokens[0])
      cmd = GPLCommand.named(tokens[0])
      if cmd != nil
        cmd.evalute
        return ""
      end
    end
    
    tokens.each { |word|
      ok = false
      if OPERATORS.include?(word) 
        ok = true  
      end
      if not ok 
        if GPLNumber.ok_str?(word)
          ok = true
        end
      end
      if not ok 
        puts "Unkown token: #{word}"
        return s
      end
    }
    tokens.join(" ")
  end

  class GPLContext
    @lines
    @file
    @show_index
    attr_accessor :lines, :show_index
    def initialize
      @show_index = true
      @lines = []
    end
    def add_line(statement)
      @lines.push(statement)
    end
    def file_bind?
      @file != nil
    end
    # debugging
    def list
      if @show_index
        lines.each_with_index { |l, c|
          printf "%5d :%s\n", c, l
        }
        nil
      else
        puts lines.join("\n")
      end
    end
  end

  class GPLContextTest
    def self.setup_sample
      gplc = GPLContext.new
      gplc.add_line('KE#N:=+3.141592+3*6+(3-2 - -2.0+2**3)')
      gplc.add_line('KE$N := +3.141592 + 3 * 6 + (3 - 2 - -2.0 + 2 ** 3)')
      gplc.add_line('IF (LENGTH(FILEINFO TEMPLATE_DF))<5 THEN')
      gplc.add_line('|  IF (LIB_NAME INDEXOF ":")>SIZE LIB_NAME THEN LIB_NAME:="GPLII:",LIB_NAME ENDIF')
      gplc.add_line('  IF X_CHK>0 THEN D_CHK:="Y" ELSE D_CHK:="N" ENDIF')
      gplc.add_line('  "   Check the Processed Structure Name (",D_CHK,"): <0>"')
      gplc.add_line('  "   Check the Processed Structure Name (",D_CHK,"): <0>" ,^')
      gplc.add_line('  IF PRIO_MSK>=4 THEN PRIO:="D"')
      return gplc
    end

    def self.test1line
      gplc = setup_sample
      gplc.lines.each { |statement|
        le = GPLLineContext.new(statement)
        p statement
        p le.as_html_tag
        p le.tokens_from_nsrange
        p (le.ranges)
        p le.nsranges
        p le.unresolved_symbols
        if GPLNumber::ARRAY_RE =~  statement
          puts "### DEBUG ### ARRAY LITERAL FOUND"
          p Regexp.last_match[0]
        end
        puts ""
      }
      gplc
    end
  end


  class GPLToken
    @category
    @range
    @parent
    attr_reader :range, :category

    def initialize(parent, range)
      @category = :NIL
      @range = range
      @parent = parent
    end

    def current_tokens
      @parent.tokens
    end

    def ==(other)
      other.to_s == to_s &&
      @range[0] == other.range[0] &&
      @range[1] == other.range[1]
    end

    def to_s
      @parent.statement[ @range[0], @range[1] ]
    end

    def statement
      @parent.statement
    end

    def index
      current_tokens.index(self)
    end

    def left_str(length = 0)
      result = statement[0, @range[0]]
      if length != 0
        result = result[-length, result.length]
      end
      result
    end

    def right_str(length = 0)
      first = @range[0] + @range[1]
      result = statement[first, statement.length]
      if result == nil then result = '' end
      if result.length > 0
        if length != 0
          result = result[0, length]
        end
      end
      result
    end

    def left_token_str
      t = prev_token
      if t == nil then "" else t.to_s end
    end

    def right_token_str
      t = next_token
      if t == nil then "" else t.to_s end
    end

    def prev_token
      prev_index = index - 1
      if index == 0
        return nil
      end
      if index > current_tokens.size
        return nil
      end
      current_tokens[prev_index]
    end

    def next_token
      next_index = index + 1
      if index == 0
        return nil
      end
      if index > current_tokens.size
        return nil
      end
      current_tokens[next_index]
    end

    def as_html_tag
      '<span class="' + @category.to_s.downcase + '">' + CGI.escapeHTML(to_s) + '</span>'
    end

    def inspect_once
      @category = category_of(self.to_s)
      self
    end
  end

  class GPLLineContext < GPLToken
    TOKEN_DELIMS = '+-*/:=()^%!<>,|'.split(//)
    DOUBLE_KEYS = [':=', '<>', '>=', '<=']
    DOUBLE_KEYS_FIRST_CHARS = DOUBLE_KEYS.collect { |dc| dc[0...1] }.uniq
    @statement
    @tokens
    @ranges
    attr_reader :ranges
    attr_reader :statement

    def initialize(statement) 
      @statement = statement
      @tokens = nil
      @ranges = []
    end

    def add_range(range)
      @ranges.push(range)
    end

    class Scanner
      @token
      @token_tree 
      @index
      attr_accessor :index

      def initialize(token_tree)
        @token = ''
        @index = 0
        @token_tree = token_tree
      end
      
      def append(c)
        @token += c
      end

      def push()
        push_with(@token)
        @token = ''    
      end

      def push_with(s, exclude_end = true)
        if s.size == 0 then return end
        last = @index
        first = @index - s.size
        #@token_tree.token_push(s)  
        if not exclude_end
          first = @index
          last = first + s.size - 1
        end
        range = Range.new(first, last, exclude_end)
        @token_tree.add_range(range)
      end
    end

    def debug_str
      tokens.collect { |t| t.to_s }
    end

    def tokens
      if @tokens == nil
        inspect_once
      end
      @tokens
    end

    def split_to_token_first
      chars = @statement.split(//)
      tokens = []
      word = ''
      in_str = false
      in_comment = false
      can_push = 0
      for c_i in (0 ... chars.size).to_a
        c = chars[c_i]
        case c
          when '|'
            if not in_str
              if not in_comment
                in_comment = true
                can_push = 3
              end
            end
          when '"'
            if not in_comment
              in_str = !in_str
            end
            if in_str
              can_push = 1
            else
              can_push = 2
            end
          else
            can_push = 0
        end
        if can_push == 0
          word += c
        end
        if word != '' and can_push > 0
          if can_push == 2
            word = '"' + word + '"'
          end
          tokens.push(word)  
          word = ''
        end
        if can_push == 3
          word = @statement[c_i, @statement.size]
          tokens.push(word)  
          word = ''
          break
        end
      end
      if word != ''
        tokens.push(word)  
        word = ''
      end
      tokens
    end

    def split_to_token
      chars = @statement.split(//)
      in_str = false
      c_i = 0
      range = nil
      next_skip = false
      scanner = Scanner.new(self)
      chars.each_with_index { |c, c_i|
        scanner.index = c_i
        if next_skip then next_skip = false ;  next end
        can_push_self = false
        can_push = false
        c_next = @statement[c_i + 1, 1]
        c_prev = @statement[c_i - 1, 1]
        if c == '"'
          in_str = !in_str
        end
        if in_str
          scanner.append(c)
        else
          if TOKEN_DELIMS.include?(c)
            can_push = true
            new_key = ''
            if DOUBLE_KEYS_FIRST_CHARS.include?(c)
                new_key = c + c_next
              if DOUBLE_KEYS.include?(new_key)
                next_skip = true
              else
                new_key = ''
              end
            end
            if new_key == ''
              can_push_self = true
            end
          elsif c == ' ' or c == "\t"
            can_push = true
          else
            scanner.append(c)
          end
        end
        if can_push
          scanner.push
        end
        if new_key == nil or new_key == '' then
          if can_push_self 
            scanner.push_with(c, false)
          end
        else
          scanner.push_with(new_key, false)
        end
      }
      scanner.index = c_i + 1
      scanner.push
      nil
    end

    def nsranges
      @ranges.collect { |r| r.as_offset_length }
    end

    def tokens_from_nsrange
      nsranges.collect { |nr| @statement[nr[0], nr[1]] }
    end

    def as_html_tag
      tokens.collect{ |tkn| 
        tkn.as_html_tag
      }.join
    end

    def unresolved_symbols
      tokens.select { |tkn|
        tkn.category == :NIL
      }.collect { |tkn|
        tkn.to_s
      }
    end
    
    ##########
    private
    ##########
    
    def inspect_once
      split_to_token
      @tokens = nsranges.collect { |nr|
        t = GPLToken.new(self, nr)
        t.inspect_once
      }
    end

  end

end
