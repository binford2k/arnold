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
          @data = { 'classes' => '' } # start out with an empty default so we don't barf if no classes are set.
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
          rescue NoMethodError
            usage
          end
        when "show"
          begin
            node = @manager.load(args[1])

            # calculate the width of the parameters column
            width = [node.parameters.keys.max_by(&:length).length() + 4, 11].max

            puts "-----------------------------"
            printf "%#{width}s: %s\n", 'GUID',        node.guid
            printf "%#{width}s: %s\n", 'Node Name',   node.name
            printf "%#{width}s: %s\n", 'MAC Address', node.macaddr
            puts
            puts "Parameters:"
            node.parameters.each { |key, val| printf "%#{width}s: %s\n", key, val }
            puts
            puts "Classes:"
            node.classes.each { |c| printf "%#{width}s\n", c }
            puts
          rescue RuntimeError => e
            puts "Whoops: #{e}"
          end
        when "remove"
          begin
            @manager.remove(args[1])
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
        puts "    * arnold show <guid>"
        puts "    * arnold new [name=<name>] [macaddr=<macaddr>] [template=<template>] [group=<group>] [classes=<class1,class2,...>] [param1=value1]..."
        puts
        exit 1
      end

    end
  end
end