#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'yaml'

CONFIG  = YAML.load_file('/etc/arnold/config.yaml')
DOCROOT = CONFIG['docroot'] || File.dirname(__FILE__)

opts = {
        :Port               => CONFIG['port'] || 8080,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :ServerType         => CONFIG['daemonize'] ? WEBrick::Daemon : WEBrick::SimpleServer,
        :DocumentRoot       => DOCROOT,
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(CONFIG['sslcert']).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(CONFIG['sslkey']).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class Server  < Sinatra::Application

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

    get '/node/:nodename' do |nodename|
      protected!
      begin
        @node = load_node(nodename)

        # We could just pass through the list of classes, but this lets us restrict classes
        # to only those specifically supported in our config. It also lets us display the
        # description on the node configuration page.
        @classes  = CONFIG['classes'].select { |name, desc| @node['classes'].include? name }
        @disabled = CONFIG['classes'].reject { |name, desc| @node['classes'].include? name }
      rescue NoMethodError => e
        # if the node doesn't exist, or if it doesn't have any classes defined, then ensure
        # that we have a node defined, and prepare a full list of classes available.
        @node ||= { 'name' => nodename }
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
      parameters = parse_params(params)
      classes    = params[:classes]
      create_node(nodename, parameters, classes)
      redirect '/'
    end

    post '/update' do
      protected!
      nodename   = params[:nodename]
      parameters = parse_params(params)
      classes    = params[:classes]
      update_node(nodename, parameters, classes)
      redirect '/'
    end

    not_found do
      halt 404, 'page not found'
    end

    error do
      @error = env['sinatra.error'].message
      #p env['sinatra.error']
      erb :error
    end

    helpers do

      # Returns an array of node names
      #
      # Just list the files in the datadir
      #
      def load_nodes()
        Dir.glob("#{CONFIG['datadir']}/*.yaml").collect { |f| File.basename(f, '.yaml') }
      end

      # Returns a hash of settings for a given node
      #
      # Enabled classes will be found under the 'classes' key.
      #
      def load_node(node)
        YAML.load_file("#{CONFIG['datadir']}/#{node}.yaml").merge!( { 'name' => node} )
      end

      # Wrapper function to check for 
      def create_node(nodename, parameters, classes)
        raise "Node Exists: press back and try again" if File.exists? "#{CONFIG['datadir']}/#{nodename}.yaml"
        write(nodename, parameters, classes)
      end

      def update_node(nodename, parameters, classes)
        raise "Invalid Node" unless File.exists? "#{CONFIG['datadir']}/#{nodename}.yaml"
        write(nodename, parameters, classes)
      end

      # Creates a node YAML file in the datadir
      #
      def write(nodename, parameters, classes)
        data = {
          'name'       => nodename,
          'parameters' => parameters,
          'classes'    => classes,
        }
        
        puts data.to_yaml
        
        File.open("#{CONFIG['datadir']}/#{nodename}.yaml", 'w') do |file|
          file.write("### This file is managed by Arnold: the provisionator.  ###\n")
          file.write("# Any manual modifications will be gleefully overwritten. #\n")
          file.write("###########################################################\n")
          file.write(data.to_yaml)
        end
      end

      # Scrapes paramters from the post params object
      #      
      def parse_params(params)
        parsed = {}
         # Pull out params, but only those which are valid variable names in Puppet
        params.each {|k,v| parsed[k.sub('param_', '')] = v if k =~ /^param_[a-zA-Z0-9_]+$/ and v != '' }
        parsed
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

Rack::Handler::WEBrick.run(Server, opts) do |server|
  [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
end
