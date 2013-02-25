require 'arnold/node'
require 'arnold/provisioner'

module Arnold
  class Provisioner::Null < Arnold::Provisioner
    def create
      puts "creating node #{@node.name}"
    end

    def install
      puts "installing"
    end
  end
end
