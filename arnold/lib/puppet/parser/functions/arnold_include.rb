Puppet::Parser::Functions::newfunction(:arnold_include, :doc => "Include classes from Arnold") do
  function_hiera_include(['classes', nil, ['arnold/nodename/%{fqdn}','arnold/macaddr/%{macaddress}']])
end
