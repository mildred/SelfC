require 'self/common'

class Self::Expr
end

class Self::String < Self::Expr
  attr_reader :string
  def initialize(str)
    @string = str
  end
end

class Self::Integer < Self::Expr
  attr_reader :integer
  def initialize(int)
    @integer = int
  end
end

class Self::Message < Self::Expr
  attr_reader :receiver
  attr_accessor :name

  def initialize(receiver, name)
    @receiver = receiver
    @name = name
    @args = []
  end
end

class Self::MessageUnary < Self::Message
end

class Self::MessageBinary < Self::Message
  attr_reader :args
end

class Self::MessageKeyword < Self::Message
  attr_reader :args
end
