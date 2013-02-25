require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

require 'arnold/server'

module Arnold
  module Controller
    class Web
      def initialize
        opts = {
                :Port               => $CONFIG[:port] || 8080,
                :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
                :ServerType         => $CONFIG[:daemonize] ? WEBrick::Daemon : WEBrick::SimpleServer,
                :DocumentRoot       => $CONFIG[:docroot],
                :SSLEnable          => true,
                :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
                :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open($CONFIG[:sslcert]).read),
                :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open($CONFIG[:sslkey]).read),
                :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
        }

        # now it's off to the races!
        Rack::Handler::WEBrick.run(Arnold::Server, opts) do |server|
          [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
        end
      end
    end
  end
end
