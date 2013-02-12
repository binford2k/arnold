#! /usr/bin/env ruby

require 'fileutils'
require 'yaml'
require 'optparse'
require 'pathname'
# Add our local path
$:.unshift File.dirname(Pathname.new(__FILE__).realpath)

require 'lib/node'
require 'lib/node_manager'
require 'lib/monkeypatch'

autoload :ServerController, 'lib/controller/server_controller'
autoload :CmdController, 'lib/controller/cmd_controller'

cmdlineopts = {}
optparse = OptionParser.new { |opts|
    opts.banner = "Usage : arnold [-c <confdir>] [-d]

        Runs the arnold daemon.

"

    opts.on("-c CONFIG", "--config CONFIG", "Choose an alternate config file. Defaults to /etc/arnold/config.yaml") do |opt|
        configfile = opt
    end

    opts.on("-d", "--debug", "Run in the foreground") do
        cmdlineopts[:debug] = true
    end

    opts.separator('')

    opts.on("-h", "--help", "Displays this help") do
        puts opts
        exit
    end
}
optparse.parse!

# Load default configuration data, deferring to command line overrides
configfile ||= '/etc/arnold/config.yaml'
$CONFIG = YAML.load_file(configfile)
$CONFIG.merge!(cmdlineopts)
$CONFIG[:debug] ||= ! $CONFIG['daemonize']
$CONFIG['docroot'] ||= File.dirname(__FILE__)
$CONFIG['backend'] ||= 'NullProvisioner'

begin
  # load up our provisioning backend
  require "lib/provisioner/#{$CONFIG['backend'].to_underscore}"
  $CONFIG[:provisioner] = Object::const_get($CONFIG['backend']).new
rescue NameError => e
  puts "No such provisioning backend, loading null backend!"
  require 'lib/provisioner/null_provisioner'
  $CONFIG[:provisioner] = NullProvisioner.new
end

case ARGV[0]
when 'serve'
  ServerController.new

else
  CmdController.new(ARGV)

end