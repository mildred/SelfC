require 'common'
require 'objects'
require 'expr'

class Self::Parser

  # http://docs.selflanguage.org/lexicaloverview.html
  # http://docs.selflanguage.org/syntaxoverview.html

  def initialize(file)
    @file = file
    File.open(file) { |f| @code = f.read }
    @index = 0
  end
  
  def char(i=0)
    @code[@index+i, 1]
  end
  
  def read(n=1)
    @index += n
    @code[@index-n, n]
  end
  
  def read_always(str)
    @code[@index, str.length].should == str
    @index += str.length
    warn "read '#{str}'"
  rescue
    warn "Should have #{str}, got #{@code[@index, str.length]}"
  end
  
  def read_maybe(str)
    if @code[@index, str.length] == str
      @index += str.length
      warn "read '#{str}'"
      true
    else
      false
    end
  end
  
  def read_pattern(pat)
    res = @code[@index..-1][pat]
    warn "read '#{res}'" unless res.nil?
    @index += res.length unless res.nil?
    res
  end
  
  def read_spaces
    read_pattern /\A(\s|"[^"]*")+/
  end
  
  def read_identifier
    read_pattern /\A(:\$)?[a-z_][a-zA-Z0-9_]*(?![:a-zA-Z0-9_])/
  end
  
  def read_small_keyword
    read_pattern /\A(:\$)?[a-z_][a-zA-Z0-9_]*:/
  end
  
  def read_cap_keyword
    read_pattern /\A[A-Z][a-zA-Z0-9_]*:/
  end
  
  def read_argument_name
    read_pattern /\A:[a-z_][a-zA-Z0-9_]*(?![:a-zA-Z0-9_])/
  end
  
  def read_operator(op=nil)
    chars = Regexp.escape '!@#$%^&*-+=~/?<>,;|\'\\'
    if op.nil?
      read_pattern /\A[#{chars}]+/
    else
      op = Regexp.escape op
      read_pattern /\A#{op}(?![#{chars}])/
    end
  end
  
  def read_number
    i = read_integer
    return Self::Integer.new(i) unless i.nil?
  end
  
  def read_integer
    num = read_pattern /\A-?[0-9]+/
    num = num.to_i unless num.nil?
    num
  end
  
  def read_string
    read_pattern /\A'([^\\']|\\[tbnfrva0\\'"\?]|\\x[0-9a-fA-F][0-9a-fA-F]|\\[do][0-9][0-9][0-9])*'/
  end
  
  def read_constant
    c = read_number
    return c unless c.nil?
    c = read_string
    return Self::String.new(c) unless c.nil?
    read_object
  end
  
  def read_expr
    read_keyword_msg
  end
  
  def read_unary_msg(receiver=nil)
    receiver = read_constant if receiver.nil? # maybe
    read_spaces
    idf = read_identifier
    msg = receiver
    while not idf.nil?
      msg = Self::MessageBinary.new(msg, idf)
      read_spaces
      idf = read_identifier
    end
    msg
  end
  
  def read_binary_msg(receiver=nil)
    receiver = read_unary_msg if receiver.nil? # maybe
    op = read_operator
    if op.nil?
      receiver
    else
      msg = Self::MessageBinary.new(receiver, op)
      read_spaces
      msg.args << read_unary_msg
      read_spaces
      while read_operator op
        msg = Self::MessageBinary.new(msg, op)
        read_spaces
        msg.args << read_unary_msg
        read_spaces
      end
      msg
    end
  end
  
  def read_keyword_msg
    receiver = read_binary_msg # maybe
    key = read_small_keyword
    if key.nil?
      read_binary_msg(receiver)
    else
      msg = receiver
      while not key.nil?
        msg = Self::MessageKeyword.new(msg, key)
        read_spaces
        msg.args << read_binary_msg
        read_spaces
        cap = read_cap_keyword
        while not cap.nil?
          msg.name += cap
          read_spaces
          msg.args << read_binary_msg
          read_spaces
          cap = read_cap_keyword
        end
        read_spaces
        key = read_small_keyword
      end
      msg
    end
  end
  
  def read_object
    read_regular_object
    # TODO: read_block
  end
  
  def read_regular_object
    return nil unless read_maybe "("
    object = Self::Object.new
    read_spaces
    if read_maybe "|"
      read_spaces
      read_slot_list
      read_spaces
      read_always "|"
      read_spaces
    end
    read_code(object)
    read_always ")"
    return object
  end
  
  def read_slot_list
    s = read_slot
    while not s.nil?
      read_spaces
      break unless read_maybe '.'
      read_spaces
      s = read_slot
    end
    if read_maybe '.'
      read_spaces
    end
  end
  
  def read_slot
    s = read_arg_slot
    return s unless s.nil?
    s = read_data_slot
    return s unless s.nil?
    s = read_binary_slot
    return s unless s.nil?
    read_keyword_slot
  end
  
  def read_arg_slot
    arg = read_argument_name
    return nil if arg.nil?
    read_spaces
  end
  
  def read_data_slot
    idf = read_identifier
    return nil if idf.nil?
    read_spaces
    read_maybe '*'
    read_spaces
    if read_operator "<-"
      read_spaces
      read_expr
    elsif read_operator "="
      read_spaces
      read_expr
    end
    read_spaces
  end
  
  def read_binary_slot
    op = read_operator
    return nil if op.nil?
    read_spaces
    idf = read_identifier # Maybe
    read_spaces
    read_always "="
    read_spaces
    read_regular_object
    read_spaces
  end
  
  def read_keyword_slot
    key = read_small_keyword
    return nil if key.nil?
    read_spaces
    idf = read_identifier # Maybe
    read_spaces
    cap = read_cap_keyword
    while not cap.nil?
      read_spaces
      idf = read_identifier # Maybe
      read_spaces
      cap = read_cap_keyword
    end
    read_spaces
    read_always "="
    read_spaces
    read_regular_object
    read_spaces
  end
  
  def read_code(obj)
    e = read_expr
    obj.expressions << e unless e.nil?
    read_spaces
    while read_maybe '.'
      read_spaces
      e = read_expr
      break if e.nil?
      obj.expressions << e
      read_spaces
    end
    ret = read_operator "^"
    unless ret.nil?
      read_spaces
      e = read_expr
      obj.expressions << e
      obj.return_expression = e
      read_spaces
      read_maybe "."
      read_spaces
    end
  end
  
  def parse
    object = Self::Object.new
    read_pattern /\A\#![^\n]\n/ # shebang
    read_spaces
    read_code object
    object
  end

end
