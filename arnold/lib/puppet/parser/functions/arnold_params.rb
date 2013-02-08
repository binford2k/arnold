Puppet::Parser::Functions::newfunction(:arnold_params, :doc => "Use Hiera to look up parameters and populate global scope") do
  params = function_hiera(['parameters', undef, ['arnold/nodename/%{fqdn}','arnold/macaddr/%{macaddress}']])
  params.each do |name, value|
    setvar(name, value)
  end
end
