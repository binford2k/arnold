module Arnold
  class Node
    attr_reader :guid, :name, :macaddr, :parameters, :classes
    @@reserved_params = ['guid', 'name', 'macaddr', 'classes']

    def initialize(guid=nil, name=nil, macaddr=nil, parameters={}, classes = [])
      # if no guid, this is intended to be a new node
      self.guid       = guid
      self.name       = name
      self.macaddr    = macaddr
      self.parameters = parameters
      self.classes    = classes
    end

    def guid=(g)
      @guid = self.class.validate(g, :guid)
    end

    def name=(n)
      @name = self.class.validate(n, :filename)
    end

    def macaddr=(m)
      @macaddr = self.class.validate(m, :macaddr)
    end

    def parameters=(p)
      @parameters = self.class.validate(p, :params)
    end

    def classes=(c)
      @classes = self.class.validate(c, :classes)
    end

    # returns classes and descriptions for classes enabled or disabled
    def enabled
      return {} if @classes.nil?
      $CONFIG[:classes].select { |name, desc| @classes.include? name }
    end

    def disabled
      return $CONFIG[:classes] if @classes.nil?
      $CONFIG[:classes].reject { |name, desc| @classes.include? name }
    end

    # Raise exceptions if the given condition fails
    #
    def self.validate(value, type=:exists)
      case type
      when :classes
        return if value.nil?
        raise "Invalid type: #{value.class}" if not value.kind_of?(Array)
        value.each { |n| raise "Invalid class: #{n}" if not $CONFIG[:classes].has_key?(n) }

      when :params
        return if value.nil?
        raise "Invalid type: #{value.class}" if not value.kind_of?(Hash)
        @@reserved_params.each { |n| raise "Invalid parameter: #{n}" if value.has_key?(n) }

      when :guid
        return if value.nil?
        raise "Invalid GUID: #{value}" if not value =~ /^([a-z0-9]){16}$/

      when :macaddr
        return if value.nil?
        value.upcase!
        raise "Invalid MAC address: #{value}" if not value =~ /^(([0-9A-F]{2}[:-]){5}([0-9A-F]{2}))?$/

      when :filename
        return if value.nil?
        raise "Invalid name: #{value}" if not value =~ /^([^\/])*$/

      when :exists
        raise "Value does not exist." if (value.nil? || value.empty?)

      end

      return value
    end

    def self.munge(value, type=:upcase)
      case type
      when :upcase
        return value.nil? ? nil : value.upcase
      when :params
        return value.reject { |name, val| @@reserved_params.include? name }
      end
    end
  end
end