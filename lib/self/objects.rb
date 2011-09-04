require 'self/common'
require 'self/expr'

class Self::Slot
  attr_reader :name

end

class Self::Object < Self::Expr
  attr_reader :slots
  attr_reader :expressions
  attr_accessor :return_expression
  attr_accessor :lobby
  
  def initialize
    @lobby = false
    @slots = []
    @expressions = []
  end
  
  def generate(g)
    if @lobby
      @@proto_string = g.global
    end
    g.function :initializer => true do |g2|
      # ...
    end
    f = g.function do |g2|
      g2.sub_activate do
        
      end
      g2.sub_message do
        if @lobby
          a = g2.icmp :eq, g2.arg_mode, 0
          g2.condition a do |g3|
            g3.if_true do
            end
            g3.if_false do
            end
          end
        end
      end
    end
  end
  
end

