require 'common'

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
  end
  
  def read_maybe(str)
    if @code[@index, str.length] == str
      @index += str.length
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
    read_pattern /\A(\s|"[^"]*")*/
  end
  
  def read_identifier
    read_pattern /\A[a-z_][a-zA-Z0-9_]*/
  end
  
  def read_small_keyword
    read_pattern /\A[a-z_][a-zA-Z0-9_]*:/
  end
  
  def read_cap_keyword
    read_pattern /\A[A-Z][a-zA-Z0-9_]*:/
  end
  
  def read_argument_name
    read_pattern /\A:[a-z_][a-zA-Z0-9_]*/
  end
  
  def read_operator(op=nil)
    chars = Regexp.escape '!@#$%^&*-+=~/?<>,;|\'\\'
    if op.nil?
      read_pattern /\A[#{chars}]+/
    else
      op = Regexp.escape op
      read_pattern /\A#{op}[^#{chars}]+/
    end
  end
  
  def read_number
    read_integer
  end
  
  def read_integer
    num = read_pattern /\A-?([0-9]+[Rr])[0-9][0-9a-zA-Z]*?/
    num = num.to_i unless num.nil?
    num
  end
  
  def read_string
    read_pattern /\A'([^\\']|\\[tbnfrva0\\'"\?]|\\x[0-9a-fA-F][0-9a-fA-F]|\\[do][0-9][0-9][0-9])*'/
  end
  
  def read_expr
    read_keyword_msg
  end
  
  def read_unary_msg
    receiver = read_constant
    idf = read_identifier
    while not idf.nil?
      read_spaces
      idf = read_identifier
    end
  end
  
  def read_binary_msg
    receiver = read_unary_msg # maybe
    op = read_operator
    if op.nil?
      read_unary_msg
    else
      read_spaces
      read_expr
      read_spaces
      while read_operator op
        read_spaces
        read_expr
        read_spaces
      end
    end
  end
  
  def read_keyword_msg
    receiver = read_binary_msg # maybe
    key = read_small_keyword
    if key.nil?
      read_binary_msg
    else
      while not key.nil?
        read_spaces
        read_expr
        read_spaces
        key = read_cap_keyword
        while not cap.nil?
          read_spaces
          read_expr
          read_spaces
          key = read_cap_keyword
        end
        read_spaces
        key = read_small_keyword
      end
    end
  end
  
  def read_constant
    c = read_number
    return c unless c.nil?
    c = read_string
    return c unless c.nil?
    read_object
  end
  
  def read_object
    read_regular_object
    # TODO: read_block
  end
  
  def read_regular_object
    return nil unless read_maybe "("
    read_spaces
    if char == "|"
      read
      read_spaces
      read_slot_list
      read_spaces
      read_always "|"
      read_spaces
    end
    read_code
    read_always ")"
  end
  
  def read_slot_list
    s = read_slot
    while not s.nil?
      read_spaces
      break unless char == '.'
      read.should == '.'
      read_spaces
      s = read_slot
    end
    if char == '.'
      read
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
    read_argument_name
    read_spaces
  end
  
  def read_data_slot
    idf = read_identifier
    return nil if idf.nil?
    read_spaces
    read if char == '*'
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
  
  def read_code
    read_expr
    read_spaces
    while read_maybe '.'
      read_spaces
      read_expr
      read_spaces
    end
    read_operator "^" # maybe
    read_spaces
    read_expr
    read_spaces
    read_maybe "."
    read_spaces
  end
  
  def parse
    read_pattern /\A\#![^\n]\n/ # shebang
    read_spaces
    read_expr
  end

end
