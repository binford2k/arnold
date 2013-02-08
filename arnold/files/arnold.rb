#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'fileutils'
require 'yaml'
require 'json'
require 'optparse'

SETTINGS = {}
optparse = OptionParser.new { |opts|
    opts.banner = "Usage : arnold [-c <confdir>] [-d]

        Runs the arnold daemon.

"

    opts.on("-c CONFIG", "--config CONFIG", "Choose an alternate config file. Defaults to /etc/arnold/config.yaml") do |opt|
        SETTINGS[:configfile] = opt
    end

    opts.on("-d", "--debug", "Run in the foreground") do
        SETTINGS[:debug] = true
    end

    opts.separator('')

    opts.on("-h", "--help", "Displays this help") do
        puts opts
        exit
    end
}
optparse.parse!

# Load default configuration data, deferring to command line overrides
SETTINGS[:configfile] ||= '/etc/arnold/config.yaml'
SETTINGS[:config]       = YAML.load_file(SETTINGS[:configfile])
SETTINGS[:debug]      ||= SETTINGS[:config]['daemonize']

CONFIG = SETTINGS[:config]
DOCROOT = CONFIG['docroot'] || File.dirname(__FILE__)
DATADIR = "#{CONFIG['datadir']}/arnold"

opts = {
        :Port               => CONFIG['port'] || 8080,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :ServerType         => SETTINGS[:debug] ? WEBrick::SimpleServer : WEBrick::Daemon,
        :DocumentRoot       => DOCROOT,
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(CONFIG['sslcert']).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(CONFIG['sslkey']).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class Server < Sinatra::Application

    set     :root, DOCROOT
#    set     :dump_errors, false
#    set     :logging, false
    disable :raise_errors
    disable :show_exceptions

    get '/' do
      protected!
      @nodes = load_nodes()
      erb :nodes
    end

    get '/node/:guid' do |guid|
      protected!
      begin
        @node = load_node(guid)

        # We could just pass through the list of classes, but this lets us restrict classes
        # to only those specifically supported in our config. It also lets us display the
        # description on the node configuration page.
        @classes  = CONFIG['classes'].select { |name, desc| @node['classes'].include? name }
        @disabled = CONFIG['classes'].reject { |name, desc| @node['classes'].include? name }
      rescue NoMethodError => e
        # if the node doesn't exist, or if it doesn't have any classes defined, then ensure
        # that we have a node defined, and prepare a full list of classes available.
        @node ||= { 'guid' => guid }
        @disabled = CONFIG['classes']
      end

      erb :node
    end

    get '/new' do
      protected!
      @classes = CONFIG['classes']
      erb :new
    end

    post '/create' do
      protected!
      nodename   = params[:nodename]
      macaddr    = munge(params[:macaddr], :upcase)
      parameters = parse_params(params)
      classes    = params[:classes]
      create_node(nodename, macaddr, parameters, classes)
      redirect '/'
    end

    post '/update' do
      protected!
      guid       = params['guid']
      nodename   = params[:nodename]
      macaddr    = munge(params[:macaddr], :upcase)
      parameters = parse_params(params)
      classes    = params[:classes]
      update_node(guid, nodename, macaddr, parameters, classes)
      redirect '/'
    end

    post '/api/v1/create' do
      protected!
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read

      nodename   = data['nodename']
      macaddr    = munge(data['macaddr'], :upcase)
      parameters = data['parameters']
      classes    = data['classes']

      create_node(nodename, macaddr, parameters, classes)
    end

    get '/api/v1/:guid' do |guid|
      protected!
      begin
        node = load_node(guid)
      rescue NoMethodError => e
        node ||= { 'guid' => guid }
      end

      node.to_json
    end

    not_found do
      halt 404, 'page not found'
    end

    error do
      @error = env['sinatra.error'].message

      # just return the error if the api was called
      return @error if request.path =~ /^\/api/

      erb :error
    end

    helpers do

      # Returns an array of nodes
      #
      def load_nodes()
        nodes={}
        Dir.glob("#{DATADIR}/*.yaml").each do |file|
          data = YAML.load_file(file)
          guid = File.basename(file, '.yaml')
          nodes[guid] = {
            'name'    => data['name'],
            'macaddr' => data['macaddr'],
          }
        end
        nodes
      end

      # Returns a hash of settings for a given node
      #
      # Enabled classes will be found under the 'classes' key.
      #
      def load_node(guid)
        YAML.load_file("#{DATADIR}/#{guid}.yaml").merge!( 'guid' => guid )
      end

      # Wrapper function to check for
      def create_node(nodename, macaddr, parameters, classes)
        raise "Must have a node name or mac address!" if nada(nodename) and nada(macaddr)
        raise "Node name exists: please try again" if File.exists? "#{DATADIR}/nodename/#{nodename}.yaml"
        raise "MAC address exists: please try again" if File.exists? "#{DATADIR}/macaddr/#{macaddr}.yaml"

        guid = nil
        5.times do
          guid = (0..16).to_a.map{|a| rand(16).to_s(16)}.join
          break if not File.exist? "#{DATADIR}/#{guid}.yaml"
          guid = nil
        end
        raise "GUID generation failed!" if guid.nil?

        write(guid, nodename, macaddr, parameters, classes)

        return guid
      end

      def update_node(guid, nodename, macaddr, parameters, classes)
        raise "Invalid Node" unless File.exists? "#{DATADIR}/#{guid}.yaml"
        write(guid, nodename, macaddr, parameters, classes)
      end

      # Creates a node YAML file in the datadir
      #
      def write(guid, nodename, macaddr, parameters, classes)
        # normalize and then validate our input
        parameters = {} if not parameters.kind_of?(Hash)
        classes    = [] if not classes.kind_of?(Array)

        validate(parameters, :params)
        validate(macaddr, :macaddr) unless macaddr.nil?
        validate(nodename, :filename) unless nodename.nil?

        data = {
          'parameters' => parameters,
          'classes'    => classes,
        }
        data['name']    = nodename if not nada(nodename)
        data['macaddr'] = macaddr  if not nada(macaddr)

        # duplicate the parameters hash. This allows hiera() calls to work as expected.
        # Principle of least surprise, ya know.
        data.merge! parameters

        File.open("#{DATADIR}/#{guid}.yaml", 'w') do |file|
          file.write("###########################################################\n")
          file.write("### This file is managed by Arnold: the provisionator.  ###\n")
          file.write("# Any manual modifications will be gleefully overwritten. #\n")
          file.write("###########################################################\n")
          file.write(data.to_yaml)
        end

        make_link(guid, macaddr, :macaddr)
        make_link(guid, nodename, :nodename)
        remove_stale_symlinks("#{DATADIR}/macaddr/")
      end

      # Scrapes paramters from the post params object
      #
      def parse_params(params)
        parsed = {}
         # Pull out params, but only those which are valid variable names in Puppet
        params.each {|k,v| parsed[k.sub('param_', '')] = v if k =~ /^param_[a-zA-Z0-9_]+$/ and v != '' }
        parsed
      end

      def make_link(guid, file, type)
        raise "Invalid type" if not [ :nodename, :macaddr].include? type
        validate(guid, :filename)

        begin
          if not (file.nil? || file.empty?)
            File.symlink("#{DATADIR}/#{guid}.yaml", "#{DATADIR}/#{type}/#{file}.yaml")
          else
            File.unlink("#{DATADIR}/#{type}/#{file}.yaml")
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

      # a helper to indicate an empty/nil var
      def nada(value)
        (value.nil? || value.empty?)
      end

      # Perform any input munging needed
      #
      def munge(value, type=:upcase)
        case type
        when :upcase
          return nada(value) ? nil : value.upcase
        end
      end

      # Raise exceptions if the given condition fails
      #
      def validate(value, type=:exists)
        case type
        when :params
          ['guid', 'name', 'macaddr', 'classes'].each { |n| raise "Invalid parameter: #{n}" if value.has_key?(n) }

        when :macaddr
          raise "Invalid MAC address: #{value}" if not value =~ /^(([0-9A-F]{2}[:-]){5}([0-9A-F]{2}))?$/

        when :filename
          raise "Invalid name: #{value}" if not value =~ /^([^\/])*$/

        when :exists
          raise "Value does not exist." if nada(value)

        end
      end

      # Basic auth boilerplate
      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [CONFIG['user'], CONFIG['password']]
      end

    end
end

def makedir(path)
  if not File.exist? "#{path}"
    FileUtils.mkdir_p "#{path}"
  end
end

# make sure our data directories exist
makedir "#{DATADIR}"
makedir "#{DATADIR}/macaddr/"
makedir "#{DATADIR}/nodename/"

# now it's off to the races!
Rack::Handler::WEBrick.run(Server, opts) do |server|
  [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
end
