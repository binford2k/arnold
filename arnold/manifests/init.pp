class arnold {
  hiera_include('classes', undef, ['arnold/nodename/%{fqdn}','arnold/macaddr/%{macaddress}'])
}