require 'common'
require 'expr'

class Self::Slot
  attr_reader :name

end

class Self::Object < Self::Expr
  attr_reader :slots
  attr_reader :expressions
  attr_accessor :return_expression
  
  def initialize
    @slots = []
    @expressions = []
  end
  
end

