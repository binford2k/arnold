require 'lib/node'
require 'lib/provisioner'

class NullProvisioner < Provisioner
  def create
    puts "creating node #{@node.name}"
  end
  
  def install
    puts "installing"
  end  
end
