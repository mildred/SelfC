require 'common'
require 'parser'

class Self::SelfC
  
  def help(*args)
    warn "Help"
    warn args.inspect
  end
  
  def compile(cluster)
    warn "Compile #{cluster}"
    parser = Parser.new(cluster).parse
#  rescue Exception => e
#    warn e
#    warn e.backtrace.join "\n\t"
#    exit 1
  end
  
end

