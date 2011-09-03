require 'self/common'
require 'self/parser'
require 'self/generator'

class Self::SelfC
  
  def help(*args)
    warn "Help"
    warn args.inspect
  end
  
  def compile(cluster)
    warn "Compile #{cluster}"
    parser = Parser.new cluster
    object = parser.parse
    gen    = Generator.new
    result = gen.unit do |g|
      object.generate g
    end
    puts result
#  rescue Exception => e
#    warn e
#    warn e.backtrace.join "\n\t"
#    exit 1
  end
  
end

