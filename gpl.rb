#!/usr/bin/env ruby
# vim: sw=2 ts=2 ai

module GPL

  MODES = [ 'LOGICAL', 'INTEGER', 'INTEGER2', 'REAL', 'REAL2', 'CHAR' ]
  FLOWS = [
      'IF', 'THEN', 'ELIF', 'ELSE', 'ENDIF', 'GOTO',
      'DO', 'WHILE', 'UNTIL', 'ENDDO', 'SWITCH', 'ENDSWITCH', 
      'CASE', 'OF', 'OUT', 'ENDSUB'] 
    
  METHOD_KINDS = ['FUNCTION', 'PROCEDURE']
  METHOD_ARGTYPES = ['NILADIC', 'MONADIC', 'DYADIC']
  STORAGE_CLASSES = ['EXTERNAL', 'LOCAL', 'GLOBAL']
  
  RESERVED = [
    FLOWS,STORAGE_CLASSES, METHOD_KINDS, METHOD_ARGTYPES, MODES].flatten
  
  OPERATORS = [ '+', '-', '/', '%', '*' ]
  
  ESCAPE = '^'
  STRING_ESCAPE = '"'
  
  KEY_NAME        = 0
  KEY_PRECEDENCE = 1
  KEY_ARGTYPES   = 2
  OP_TABLES = [
  
    ['[',           377, [:list]],
    [']',           377, [:list]],
    ['(',           376, [:expr]],
    [')',           376, [:expr]],
    ['+',            20, [:array]],
    ['-',            20, [:array]],
    ['*',            20, [:array]],
    ['%',            20, [:array]],
  
    ['ABS'         , 20, [:array]],
    ['ARCTAN'      , 20, [:array]],
    ['TAN'         , 20, [:array]],
    ['CEILING'     , 20, [:array]],
    ['COS'         , 20, [:array]],
    ['FLOOR'       , 20, [:array]],
    ['GRADEDOWN'   , 20, [:matrix]],
    ['GRADEUP'     , 20, [:matrix]],
    ['GRADEDOWN'   , 20, [:vector]],
    ['GRADEUP'     , 20, [:vector]],
    ['LN'          , 20, [:array]],
    ['NOT'         , 20, [:array]],
  
    ['LOGBASE'    , 17, [:array, :array]],
    ['POWER'      , 17, [:array, :array]],
  
    ['*'          , 16, [:expr, :expr]],
    ['%'          , 16, [:expr, :expr]],
    ['MAX'        , 16, [:array, :array]],
    ['MIN'        , 16, [:array, :array]],
    ['MOD'        , 16, [:array, :array]],
  
    ['+'          , 15, [:array, :array]],
    ['-'          , 15, [:array, :array]],
    
    ['='          , 13, [:array, :array]],
    ['<'          , 13, [:array, :array]],
    ['>'          , 13, [:array, :array]],
    ['<='         , 13, [:array, :array]],
    ['>='         , 13, [:array, :array]],
    ['<>'         , 13, [:array, :array]],
    ['EQ'         , 13, [:array, :array]],
    ['GEQ'        , 13, [:array, :array]],
    ['GT'         , 13, [:array, :array]],
    ['IN'         , 13, [:array, :vector]],
    ['LEQ'        , 13, [:array, :array]],
    ['NEQ'        , 13, [:array, :array]],
  
    ['OR'          , 12, [:array, :array]],
    ['XOR'         , 12, [:array, :array]],
    ['NOR'         , 12, [:array, :array]],
  
    ['NAND'        , 11, [:array, :array]],
    ['AND'         , 11, [:array, :array]],
    
    ['IOTA'       , 10, [:array]],  # <n> or <n> <m> or <n> <step> <m>
    ['LENGTH'     , 10, [:list]],
    ['SHAPE'      , 10, [:array]],
    ['SIZE'       , 10, [:array]],
    [','          , 10, [:array]],
    ['RANK'       , 10, [:array]],
  
    ['RESHAPE'    ,  7, [:vector, :array]],
    ['INDEXOF'    ,  7, [:vector, :array]],
    [','          ,  6, [:vector, :vector]],
    [';'          ,  5, [:list, :list]],
    [':='         ,  0, [:variable, :expr]],
  
    ['TYPEOF'      , -1, [:array]],
    ['SORT'        , -1, [:vector]],
    ['SORTDOWN'    , -1, [:vector]],
    ['SORT'        , -1, [:matrix]],
    ['SORTDOWN'    , -1, [:matrix]],
    ['EXP'         , -1, [:array]],
    ['PI'          , -1, [:array]],
    ['INDICES_OF'  , -1, [:array, :array]],
    ['MIN_MAX'     , -1, [:array]],
    ['BITAND'      , -1, [:vector, :vector]],
    ['BITOR'       , -1, [:vector, :vector]],
    ['BITXOR'      , -1, [:vector, :vector]],
  ]
  
  def specs_of(op_name)
    v = OP_TABLES.select { |spec| spec[KEY_NAME] == op_name }  
    v.size == 0 ? nil : v
  end
  
  def all_op_keys
    OP_TABLES.collect { |spec| spec[KEY_NAME] }.uniq  
  end
  
  def arg_specs_of(op_name)    
    specs = specs_of(op_name)
    return nil unless specs
    specs.collect { |spec| spec[KEY_ARGTYPES] }
  end

  #flatten nested array
  def arg_types(op_name)
    arg_specs = arg_specs_of(op_name)
    if arg_specs.size == 1
      return arg_specs.flatten
    end
    arg_specs
  end

  def op_type_of(spec_arg)
    if spec_arg.nil? or not spec_arg.kind_of?(Array)
      raise ArgumentError.new("argument mut be array")
    end
    case spec_arg.size
      when 0
        return :NILADIC
      when 1
        return :MONADIC
      when 2
        return :DYADIC
    end
  end
  
  def op_types_of(op_name) 
    type = nil
    if not all_op_keys.include?(op_name)
      return type
    end
    specs = specs_of(op_name)
    specs.collect { |spec|
      arg_type_of(spec[KEY_ARGTYPES])
    }
  end
  
  def flow?(text)
    FLOWS.include?(text)
  end
  
  def operator?(text)
    all_op_keys.include?(text)
  end
  
  def known_symbol?(text)
    RESERVED.include?(text)
  end
  
  def multi_operators
    all_op_keys.select { |spec| specs_of(spec).size == 2 }      
  end
  
  def multi_operator?(text)
    multi_operators.include?(text)
  end

  module_function :op_type_of, :operator?, :flow?, :all_op_keys
  module_function :known_symbol?
end

