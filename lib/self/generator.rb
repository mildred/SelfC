require 'self/common'

class Self::Generator
  attr_reader :code

  def unit(&blc)
    @initializers = []
    @global_idf = 0
    @code = ""
    @code << "%self.call   = type void (%self.object, i32) * \n"
    @code << "%self.object = type { %self.call } *\n"
    @code << "\n"
    @code << "@self.cst.string = private unnamed_addr constant [8 x i8] c\"string:\\00\"\n"
    @code << "\n"
    @code << "declare i32 @memcmp(i8*, i8*, i32)\n"
    @code << "\n"
    blc.call self
    unless @initializers.empty?
      @code << "@llvm.global_ctors = appending global [#{@initializers.length} x { i32, void ()* }] ["
      @initializers.each do |i|
        @code << "{ i32, void ()* } { i32 #{i[0]}, void ()* #{i[1]}}, "
      end
      @code.slice!(-2..-1)
      @code << "]\n\n"
    end
    @code << "define i32 @main () {\n"
    @code << "  ret i32 0\n"
    @code << "}\n\n"
    @code
  end
  
  def cst_string
    gid :symbol => "self.cst.string", :type => "[8 x i8]*"
  end
  
  def cst_string_length
    7
  end
  
  def global
    name = gid
    @code << "#{name} = global %self.object null\n\n"
    name
  end
  
  def function(args = {}, &blc)
    name = gid :symbol => args[:name]
    if args[:initializer]
      prio = if args[:priority] then args[:priority] else 65535 end
      @initializers << [prio, name]
      @code << "define void #{name} () {\n"
      ret = "void"
      g = Function.new(self)
    else
      @code << "define %self.object #{name} (%self.object %self, i32 %mode) {\n"
      ret = "%self.object %self"
      g = SelfFunction.new(self)
    end
    blc.call(g)
    g.finalize
    @code << g.code
    @code << "  ret #{ret}\n"
    @code << "}\n\n"
    name
  end

private

  def gid(args={})
    if args[:symbol].nil?
      id = @global_idf
      @global_idf += 1
      return Self::Generator::Reg.new("@", id, args[:type])
    else
      return Self::Generator::Reg.new("@", args[:symbol], args[:type])
    end
  end

end

class Self::Generator::Reg
  attr_accessor :type

  def initialize(kind, string, type = nil)
    @kind = kind
    @string = string
    @type = type
  end

  def to_s
    return @kind if @string.nil?
    return "#{@kind}#{@string}" if @string.kind_of? Integer
    return "#{@kind}\"#{@string}\""
  end
  
  def arg
    "#{type} #{to_s}"
  end

end

class Self::Generator::Condition
  def initialize(function, ltrue, lfalse, lend)
    @function = function
    @ltrue = ltrue
    @lfalse = lfalse
    @lend = lend
  end
  
  def if_true(&blc)
    @function.code << "\n#{@ltrue}:\n"
    blc.call
    @function.code << "  br label %#{@lend}\n"
  end
  
  def if_false(&blc)
    @function.code << "\n#{@lfalse}:\n"
    blc.call
    @function.code << "  br label %#{@lend}\n"
  end
  
  def finalize
    @function.code << "\n#{@lend}:\n"
  end
end

class Self::Generator::Function
  attr_reader :code
  attr_reader :label_end

  def initialize(g)
    @gen = g
    @code = ""
    @local_idf = 1
    @local_label_idf = 1
    @label_end = label_id
  end
  
  def condition(bool, &blc)
    ltrue = label_id
    lfalse = label_id
    @code << "  br #{arg bool}, label %#{ltrue}, label %#{lfalse}\n"
    cond = Self::Generator::Condition.new(self, ltrue, lfalse, label_id)
    blc.call(cond)
    cond.finalize
  end
  
  def icmp(op, first, second)
    r = lid :type => 'i1'
    @code << "  #{r} = icmp #{op} #{arg first}, #{arg second}\n"
    r
  end

  def finalize
    @code << "#{@label_end}:\n"
  end

private

  def arg(obj)
    return obj.arg if obj.respond_to?(:arg)
    return obj.to_s if obj.kind_of? Integer
    return obj
  end

  def label_id
    id = @local_label_idf
    @local_label_idf += 1
    "label_#{id}"
  end

  def lid(opts = {})
    if opts[:symbol].nil?
      id = @local_idf
      @local_idf += 1
      return Self::Generator::Reg.new("%", id, opts[:type])
    else
      return Self::Generator::Reg.new("%", symbol, opts[:type])
    end
  end

end


class Self::Generator::SelfFunction < Self::Generator::Function

  def initialize(g)
    @gen = g
    @code = ""
    @local_idf = 1
    @local_label_idf = 1
    @label_end = label_id
    rinit = lid
    @linit_true = label_id
    @linit_false = label_id
    @code << "  #{rinit} = icmp eq i32 %mode, 0\n"
    @code << "  br i1 #{rinit}, label %#{@linit_true}, label %#{@linit_false}\n\n"
  end
  
  def arg_self
    Self::Generator::Reg.new("%", "self", "%self.object")
  end
  
  def arg_mode
    Self::Generator::Reg.new("%", "mode", "i32")
  end
  
  def sub_activate(&blc)
    @code << "#{@linit_true}:\n"
    blc.call
    @code << "  br label %#{@label_end}\n\n"
  end
  
  def sub_message(&blc)
    @code << "#{@linit_false}:\n"
    blc.call
    @code << "  br label %#{@label_end}\n\n"
  end
  
end

