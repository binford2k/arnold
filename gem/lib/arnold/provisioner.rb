require 'arnold/node'

module Arnold
  class Provisioner
    attr_accessor :node

    def initialize
    end

    def provision(node)
      @node = node
      create
      install
    end

    def create
    end

    def install
    end

  end
end