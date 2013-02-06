class arnold {
  hiera_include('classes', undef, ['arnold/name/%{fqdn}','arnold/macaddr/%{macaddress}'])
}