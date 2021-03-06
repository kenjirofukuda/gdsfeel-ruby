#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

require 'gpl.rb'

def or_re_str(re_str_array)
  ['(', re_str_array.join('|'), ')'].join
end

module GPL

  KIND_TO_MODE_MAP = {
     LOGICAL: 1,
     INTEGER: 2,
        REAL: 3,
        CAHR: 4,
        NULL: 5,
        LIST: 6,
    INTEGER2: 7,
       REAL2: 8,
  }

  class DataStructure
    @ruby_value
    def self.re_str() '' end
    
    def rank() 0 end

    def size() 0 end

    def kind() :NIL end

    def type() kind().to_s end
    
    def length() 1 end

    def mode() KIND_TO_MODE_MAP[kind] end
    
    def pr
      p @ruby_value
    end

    def gexpr() "" end
    
    def inspect
      sprintf "#<%s v=%s>", self.type, @ruby_value
    end

    def attr
      map = Hash.new
      [:rank, :size, :type, :length, :mode].each {|s|
        map[s] = self.send(s)      
      }
      map
    end
    
    def self.ok_str?(s)
      re = Regexp.new('^' + self.re_str + '$')
      if (re =~ s) != nil
        return true
      end
      false
    end
  end

  class Scalar < DataStructure
    def rank() 1 end
    def size() 1 end
    def kind() :SCALAR end
  end

  class Number < Scalar
    def gexpr() @ruby_value.to_s end
  end

  class Logical < Number
    def self.re_str
      '(1|0|TRUE|FALSE)'
    end

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
      if @ruby_value then "1" else "0" end
    end
    
    def kind() :LOGICAL end

  end

  TRUE = Logical.new("TRUE").freeze
  FALSE = Logical.new("FALSE").freeze

  class Real < Number
    def self.re_str
      '([-])?([\d]+)*\.[\d]*'
    end

    def initialize(str)
      @ruby_value = str.to_f
    end

    def kind() :REAL end

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

  end

  class Integer < Number
    def self.re_str
      '([-])?[\d]+'
    end

    def initialize(str)
      @ruby_value = str.to_i
    end

    def kind
      if @ruby_value.between?(-32768, 32767) then
        :INTEGER
      else
        :INTEGER2
      end
    end
    
  end

  class Float < Real
    def self.re_str
      [ '(', Real::re_str, '|', Integer::re_str, ')',
      '(e|E)', Integer::re_str].join
    end
  end

  class Number
    def self.re_str
      or_re_str([Integer::re_str, Real::re_str, Float::re_str])
    end
    
    ARRAY_RE_STR = '(' + self.re_str + ' )+'
    ARRAY_RE = Regexp.new(ARRAY_RE_STR)

#    def self.ok_str?(s)
#      GPLInteger.ok_str?(s) or
#      GPLReal.ok_str?(s) or
#      GPLFloat.ok_str?(s)
#    end
  end

  class Character < Number
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

    def kind
      :CHAR
    end

    def gexpr
      @ruby_value.chr
    end
    
    def ord
      @ruby_value
    end
    
    def inspect
      sprintf "#<%s v=%d chr='%s'>", type, ord, gexpr
    end
    
  end

  class Container < DataStructure
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

  class Array < Container
    JOIN_STR = ' '
  end

  class Vector < Array
    JOIN_STR = ' '
    @elements
    def kind() :VECTOR end
    def rank() 1 end

    def elements
      @elements
    end
  end


  NULL = Vector.new

  class << NULL
    def gexpr() '""' end
    def kind() :NULL end
  end

  NULL.freeze

  class String < Vector
    JOIN_STR = ''

    def initialize(s)
      @ruby_value = s
      @elements = s.split(//).collect { |ch|
        Character.new(ch)
      }
    end
    
    def inspect
      sprintf "#<%s %s>", self.kind, gexpr.inspect
    end
    
  end

  class Matrix < Array
    def kind
      :MATRIX
    end
    def rank
      return 2
    end
  end

  class List < Container
    JOIN_STR = ' '
    def same_mode_only?
      false
    end
    def kind
      :LIST
    end
  end

  class ValueFactory
    def self.from_str(str)
      [Float, Real, Integer, Logical].each {|clazz|
        if clazz.ok_str?(str)
          return clazz.new(str)
        end
      }
      nil
    end
  end

end
