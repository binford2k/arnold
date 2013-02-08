Puppet::Parser::Functions::newfunction(:arnold_include, :doc => "Include classes from Arnold") do
  classes = function_hiera_array(['classes', ['*****'], ['arnold/nodename/%{fqdn}','arnold/macaddr/%{macaddress}']])

  # The version of hiera_array() shipping in Puppet 2.7 won't let you default to nothing
  return if classes = ['*****']
  classes.each do |name|
    function_include(name)
  end
end
