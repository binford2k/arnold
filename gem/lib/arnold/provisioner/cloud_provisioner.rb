require 'arnold/node'
require 'arnold/provisioner'

module Arnold
  class Provisioner::CloudProvisioner < Arnold::Provisioner
    def create
      puts "provisioning node #{@node.name}"
      puts "Would have called:"
      puts "puppet node_vmware create --name=#{@node.name} --template='#{@node.parameters['template']}' --wait-for-boot"
    end

    def install
      enc_server = "--enc-server=#{$CONFIG[:enc_server]} --enc-port=#{$CONFIG[:enc_port]}"
      enc_auth   = "--enc-ssl --enc-auth-user=#{$CONFIG[:enc_user]} --enc-auth-passwd=#{$CONFIG[:enc_password]}"

      enc        = "#{enc_server} #{enc_auth}"
      login      = "--keyfile=#{$CONFIG[:keyfile]} --login=root"

      puts "installing and classifying"
      puts "would have called:"
      puts "puppet node init --node-group=#{@node.parameters['group']} #{enc} #{login} #{@node.name}"
    end
  end
end