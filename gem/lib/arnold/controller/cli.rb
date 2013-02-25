require 'arnold/node'
require 'arnold/node_manager'

module Arnold
  module Controller
    class Cli

      def initialize(args)
        @manager = Arnold::NodeManager.new

        case args[0]
        when "help"
          usage
        when "list"
          listnodes
          exit 0
        when "new"
          args.shift
          @data = {}
          args.each do |arg|
            name, value = arg.split("=")
            @data[name] = value
          end

          begin
            node = Arnold::Node.new(nil,
                                    @data['name'],
                                    @data['macaddr'],
                                    Arnold::Node.munge(@data, :params),
                                    @data['classes'].split(','))
            @manager.write(node)

            $CONFIG[:provisioner].provision(node)
          rescue RuntimeError => e
            puts "Whoops: #{e}"
          end
        else
          puts "WAT"
          usage
        end
      end

      def listnodes
        nodes = @manager.loadall
        puts
        puts "________GUID______________________Name____________________MAC Address___"
        nodes.each do |node|
          printf "%18s │ %30s │ %18s\n", node.guid, node.name, node.macaddr
        end
        puts
      end

      def usage
        puts
        puts "Usage:"
        puts "    * arnold help"
        puts "    * arnold list"
        puts "    * arnold new [name=<name>] [macaddr=<macaddr>] [template=<template>] [group=<group>] [classes=<class1,class2,...>] [param1=value1]..."
        puts
        exit 1
      end

    end
  end
end