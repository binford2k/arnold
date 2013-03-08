require 'fileutils'
require 'yaml'

require 'arnold/node'

module Arnold
  class NodeManager

    def initialize
      @datadir = "#{$CONFIG[:datadir]}/arnold"

      # make sure our data directories exist
      makedir "#{@datadir}"
      makedir "#{@datadir}/macaddr/"
      makedir "#{@datadir}/name/"
    end

    def load(guid)
      Node.validate(guid, :guid)

      begin
        data = YAML.load_file("#{@datadir}/#{guid}.yaml")
        return Arnold::Node.new(guid, data['name'], data['macaddr'], data['parameters'], data['classes'])
      rescue Exception => e
        raise "Invalid node! #{e}"
      end
    end

    def loadall
      nodes=[]
      errors = []
      Dir.glob("#{@datadir}/*.yaml").each do |file|
        begin
          nodes << load(File.basename(file, '.yaml'))
        rescue Exception => e
          errors << e
        end
      end

      # splat out any errors loading nodes
      errors.each { |e| puts e }
      nodes
    end

    def write(node)
      raise "Must have a name or mac address!" if (node.name.nil? and node.macaddr.nil?)

      if node.guid.nil?
        raise "Node name exists: please try again" if File.exists? "#{@datadir}/name/#{node.name}.yaml"
        raise "MAC address exists: please try again" if File.exists? "#{@datadir}/macaddr/#{node.macaddr}.yaml"
        node.guid = makeguid()
      else
        raise "Invalid Node" unless File.exists? "#{@datadir}/#{node.guid}.yaml"
      end

      data = {
        'parameters' => node.parameters,
        'classes'    => node.classes,
      }
      data['name']    = node.name if node.name
      data['macaddr'] = node.macaddr  if node.macaddr

      # duplicate the parameters hash. This allows hiera() calls to work as expected.
      # Principle of least surprise, ya know.
      data.merge! node.parameters

      File.open("#{@datadir}/#{node.guid}.yaml", 'w') do |file|
        file.write("###########################################################\n")
        file.write("### This file is managed by Arnold: the provisionator.  ###\n")
        file.write("# Any manual modifications will be gleefully overwritten. #\n")
        file.write("###########################################################\n")
        file.write(data.to_yaml)
      end

      make_link(node.guid, node.macaddr, :macaddr)
      make_link(node.guid, node.name, :name)
      remove_stale_symlinks("#{@datadir}/macaddr/")
      remove_stale_symlinks("#{@datadir}/name/")

      return node.guid
    end

    def remove(guid)
      Node.validate(guid, :guid)
      File.delete("#{@datadir}/#{guid}.yaml")
      remove_stale_symlinks("#{@datadir}/macaddr/")
      remove_stale_symlinks("#{@datadir}/name/")
    end

    private
    def makedir(path)
      if not File.exist? "#{path}"
        FileUtils.mkdir_p "#{path}"
      end
    end

    def make_link(guid, file, type)
      raise "Invalid type" if not [ :name, :macaddr].include? type

      begin
        if not (file.nil? || file.empty?)
          File.symlink("#{@datadir}/#{guid}.yaml", "#{@datadir}/#{type}/#{file}.yaml")
        else
          File.unlink("#{@datadir}/#{type}/#{file}.yaml")
        end
      rescue Errno::EEXIST
        # noop
      rescue Errno::ENOENT
        # noop
      end
    end

    # just loop through a directory and get rid of any stale symlinks
    def remove_stale_symlinks(path)
      Dir.glob("#{path}/*").each { |f| File.unlink(f) if not File.exist?(f) }
    end

    def makeguid
      guid = nil
      5.times do
        guid = (0..15).to_a.map{|a| rand(16).to_s(16)}.join
        break if not File.exist? "#{@datadir}/#{guid}.yaml"
        guid = nil
      end
      raise "GUID generation failed!" if guid.nil?
      return guid
    end
  end
end
