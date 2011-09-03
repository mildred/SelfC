require 'self/common'

class Self::Generator
  attr_reader :code

  def unit(&blc)
    @initializers = []
    @global_idf = 0
    @code = ""
    @code << "%self.call   = type void () * \n"
    @code << "%self.object = type { %self.call } *\n"
    @code << "\n"
    blc.call self
    unless @initializers.empty?
      @code << "@llvm.global_ctors = appending global [#{@initializers.length} x { i32, void ()* }] ["
      @initializers.each do |i|
        @code << "{ i32, void ()* } { i32 #{i[0]}, void ()* #{i[1]}}, "
      end
      @code.slice!(-2..-1)
      @code << "]\n"
    end
    @code
  end
  
  def function(args = {}, &blc)
    name = gid args[:name]
    @code << "define void #{name} (...) {\n"
    g = Function.new(self)
    blc.call(g)
    @code << g.code
    @code << "  ret void\n"
    @code << "}\n\n"
    name
  end
  
  def init(f, prio = 65535)
    @initializers << [prio, f]
  end

private

  def gid(symbol=nil)
    if symbol.nil?
      id = @global_idf
      @global_idf += 1
      return "@#{id}"
    else
      return "@\"#{symbol}\""
    end
  end

end

class Self::Generator::Function
  attr_reader :code

  def initialize(g)
    @gen = g
    @code = ""
    @local_idf = 1
  end

private

  def lid(symbol=nil)
    if symbol.nil?
      id = @global_idf
      @global_idf += 1
      return "%#{id}"
    else
      return "%\"#{symbol}\""
    end
  end

end

