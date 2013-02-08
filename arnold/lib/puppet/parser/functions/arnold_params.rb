Puppet::Parser::Functions::newfunction(:arnold_params, :doc => "Populate current scope with parameters from Arnold") do
  params = function_hiera(['parameters', undef, ['arnold/nodename/%{fqdn}','arnold/macaddr/%{macaddress}']])
  params.each do |name, value|
    setvar(name, value)
  end
end
