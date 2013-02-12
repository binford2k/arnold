#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'

require 'lib/node'
require 'lib/node_manager'

class ServerController
  def initialize  
    opts = {
            :Port               => $CONFIG['port'] || 8080,
            :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
            :ServerType         => $CONFIG[:debug] ? WEBrick::SimpleServer : WEBrick::Daemon,
            :DocumentRoot       => $CONFIG['docroot'],
            :SSLEnable          => true,
            :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
            :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open($CONFIG['sslcert']).read),
            :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open($CONFIG['sslkey']).read),
            :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
    }
    
    # now it's off to the races!
    Rack::Handler::WEBrick.run(Server, opts) do |server|
      [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
    end
  end
end

class Server < Sinatra::Application
  set     :root, $CONFIG['docroot']
#    set     :dump_errors, false
#    set     :logging, false
  disable :raise_errors
  disable :show_exceptions
  
  def initialize
    super
    @manager = NodeManager.new()
  end
  
  get '/' do
    protected!
    @nodes = @manager.loadall()      
    erb :nodes
  end

  get '/node/:guid' do |guid|
    protected!
    @node = @manager.load(guid)
    erb :node
  end

  get '/new' do
    protected!
    @classes = $CONFIG['classes']
    erb :new
  end

  post '/create' do
    protected!
    node = Node.new(nil, params[:name], params[:macaddr], parse_params(params), params[:classes])
    @manager.write(node)
    $CONFIG[:provisioner].provision(node)
    redirect '/'
  end

  post '/update' do
    protected!
    node = Node.new(params[:guid], params[:name], params[:macaddr], parse_params(params), params[:classes])
    @manager.write(node)
    redirect '/'
  end

  post '/api/v1/create' do
    protected!
    request.body.rewind  # in case someone already read it
    data = JSON.parse request.body.read
    node = Node.new(nil, data['name'], data['macaddr'], data['parameters'], data['classes'])
    guid = @manager.write(node)
    $CONFIG[:provisioner].provision(node)
    return guid
  end

  get '/api/v1/:guid' do |guid|
    protected!
    node = @manager.load(guid)
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
    # Scrapes paramters from the post params object
    #
    def parse_params(params)
      parsed = {}
       # Pull out params, but only those which are valid variable names in Puppet
      params.each {|k,v| parsed[k.sub('param_', '')] = v if k =~ /^param_[a-zA-Z0-9_]+$/ and v != '' }
      return parsed
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
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [$CONFIG['user'], $CONFIG['password']]
    end

  end
end
