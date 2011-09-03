require 'self/common'
require 'self/expr'

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
  
  def generate(g)
    init = g.function do
      # ...
    end
    f = g.function do
      # ...
    end
    g.init init
  end
  
end

