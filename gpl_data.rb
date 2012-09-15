#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl.rb'

def or_re_str(re_str_array)
  ['(', re_str_array.join('|'), ')'].join
end

module GPL

  class GPLStruct
    @ruby_value
    def initialize
    end
    def rank
      return 0
    end
    def kind
      :NIL
    end
    def pr
      p @ruby_value
    end
    def mode
      :NIL
    end
    def gexpr
      ""
    end
    
    def inspect
      sprintf "#<%s v=%s>", self.mode, @ruby_value
    end
  end

  GPLNull = GPLStruct.new
  class << GPLNull
    def gexpr
      '""'
    end
  end

  class GPLScalar < GPLStruct
    def kind
      :SCALAR
    end
  end

  class GPLNumber < GPLScalar
    def gexpr
      @ruby_value.to_s
    end
  end

  class GPLBoolean < GPLNumber

    def initialize(str)
      @ruby_value = false
      if str.class == String
        case str
        when "0", "FALSE"
          @ruby_value = false
        when "1", "TRUE"
          @ruby_value = true
        end
      end
    end

    def gexpr
      if @ruby_value then "TRUE" else "FALSE" end
    end
    
    def mode
      :LOGICAL
    end
  end

  GPLTrue = GPLBoolean.new("TRUE")
  GPLFalse = GPLBoolean.new("FALSE")

  class GPLReal < GPLNumber
    RE_STR = '([-])?([\d]+)*\.[\d]*'

    def initialize(str)
      @ruby_value = str.to_f
    end

    def mode
      :REAL
    end

    def gexpr
      s = @ruby_value.to_s
      if (/\.0$/ =~ s)
        s = Regexp.last_match.pre_match + '.'
      else
        if @ruby_value < 0 then
          if (/^\-0\./ =~ s)
            s = '-.' + Regexp.last_match.post_match
          end
        else
          if (/^0\./ =~ s)
            s = '.' +  Regexp.last_match.post_match
          end
        end
      end
      s
    end

    def self.ok_str?(s)
      re = Regexp.new('^' + RE_STR + '$')
      if (re =~ s) != nil
        return true
      end
      false
    end
  end

  class GPLInteger < GPLNumber
    RE_STR = '([-])?[\d]+'

    def initialize(str)
      @ruby_value = str.to_i
    end

    def mode
      if @ruby_value >= -32767 and @ruby_value <= 32768 then
        :INTEGER
      else
        :INTEGER2
      end
    end
    
  end

  class GPLFloat < GPLReal
    RE_STR = [ '(', GPLReal::RE_STR, '|', GPLInteger::RE_STR, ')',
                'e', GPLInteger::RE_STR].join 

    def self.ok_str?(s)
      re = Regexp.new('^' + RE_STR + '$')
      if (re =~ s) != nil
        return true
      end
      false
    end
  end

  class GPLInteger
    def self.ok_str?(s)
      re = Regexp.new('^' + RE_STR + '$')
      if (re =~ s) != nil
        return true
      end
      false
    end
  end

  class GPLNumber
    RE_STR = or_re_str([GPLInteger::RE_STR, GPLReal::RE_STR, GPLFloat::RE_STR])
    ARRAY_RE_STR = '(' + RE_STR + ' )+'
    ARRAY_RE = Regexp.new(ARRAY_RE_STR)

    def self.ok_str?(s)
      GPLInteger.ok_str?(s) or
      GPLReal.ok_str?(s) or
      GPLFloat.ok_str?(s) 
    end
  end

  class GPLCharacter < GPLNumber
    CHAR_CONST_IN_RE_STR = '([A-Z]+|[0-9]+)'
    CHAR_CONST_RE_STR = '<' + CHAR_CONST_IN_RE_STR + '>'
    CHAR_CONST_RE = Regexp.new( '^' + CHAR_CONST_RE_STR + '$' )

    CHAR_CONST_TABLE = {
      'NUL'  => 000,
      'BEL'  => 007,
      'TAB'  => 011,
      'LF'  => 012,
      'FF'  => 014,
      'CR'  => 015,
      'NL'  => 015,
      'ESC'  => 033,
      'BROFF'  => 036,
      'BRON'  => 037,
      'LT'  => 074,
      'GT'  => 076,
      'QT'  => 042,
      'DEL'  => 177,
    }

    def self.ascii_from_const(str)
      if CHAR_CONST_RE =~ str 
        if Regexp.last_match.size >= 2 
          sym = Regexp.last_match[1]
          if CHAR_CONST_TABLE.has_key?(sym)
            return CHAR_CONST_TABLE[sym]
          elsif /[0-9]+/ =~ sym
            return eval("0o" + sym)
          end
        end
      else
        return nil
      end
    end

    def initialize(s)
      @ruby_value= nil
      if s.class == String
        if s.size == 1 
          @ruby_value = s[0]
        else
          v = self.class.ascii_from_const(s)
          if v != nil
            @ruby_value = v
          end
        end
      else
        if s >= 0 and s <= 255 
          @ruby_value = s
        end
      end
    end

    def mode
      :CHAR
    end

    def gexpr
      @ruby_value.chr
    end
    
    def ord
      @ruby_value
    end
    
    def inspect
      sprintf "#<%s v=%d chr='%s'>", mode, ord, gexpr
    end
    
  end

  class GPLContainer < GPLStruct
    JOIN_STR = ' '
    def same_mode_only?
      true
    end

    def elements
      []
    end

    def gexpr
      elements.collect { |go| go.gexpr }.join(self.class::JOIN_STR)
    end
  end

  class GPLArray < GPLContainer
    JOIN_STR = ' '
  end

  class GPLVector < GPLArray
    JOIN_STR = ' '
    @elements
    def kind
      :VECTOR
    end
    def rank
      1
    end
    def elements
      @elements
    end
  end

  class GPLString < GPLVector
    JOIN_STR = ''

    def initialize(s)
      @ruby_value = s
      @elements = s.split(//).collect { |ch|
        GPLCharacter.new(ch)
      }
    end
    
    def inspect
      sprintf "#<%s %s>", self.kind, gexpr.inspect
    end
    
  end

  class GPLMatrix < GPLArray
    def kind
      :MATRIX
    end
    def rank
      return 2
    end
  end

  class GPLList < GPLContainer
    JOIN_STR = ' '
    def same_mode_only?
      false
    end
    def kind
      :LIST
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

end
