class arnold::provisionator (
  $reusecerts   = true,     # default to using the Puppet Master's certs, otherwise generate our own.
  $template     = 'arnold/config.yaml.erb',
  $hieradata    = undef,    # default to /etc/<puppetroot>/hieradata
  $user         = 'admin',
  $password     = 'admin',
  $port         = 9090,
  $classes      = {},       # specify a hash of classes you'd like in your config
  $customconfig = false,
) {
  File {
    owner   => root,
    group   => wheel,
    mode    => '0644',
    notify  => Service['arnold'],
  }

  $puppetroot = $::puppetversion ? {
      /Enterprise/ => '/etc/puppetlabs/puppet',
      default      => '/etc/puppet'
    }

  if $reusecerts {
    $certfile = "${puppetroot}/ssl/certs/${::clientcert}.pem"
    $keyfile  = "${puppetroot}/ssl/private_keys/${::clientcert}.pem"
  } else {
    $certsubj = "/C=US/ST=Oregon/L=Portland/O=Puppet Labs/CN=${::clientcert}"
    $certfile = "/etc/arnold/certs/server.crt"
    $keyfile  = "/etc/arnold/certs/server.key"

    file { '/etc/arnold/certs':
      ensure => directory,
      before => Exec['arnold_cert'];
    }

    exec { 'arnold_cert':
      command => "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj '${certsubj}' -keyout ${keyfile}  -out ${certfile}",
      path    => '/usr/bin:/bin',
      creates => "${keyfile}",
    }
  }

  $real_hieradata = $hieradata ? {
    undef   => "${puppetroot}/hieradata",
    default => $hieradata,
  }

  package { 'arnold':
    ensure   => present,
    provider => 'gem',
  }

  file { '/etc/arnold':
    ensure  => directory,
  }

  if ! $customconfig {
    file { '/etc/arnold/config.yaml':
      ensure => file,
      content => template($template),
    }
  }

  file { '/etc/init.d/arnold':
    ensure => file,
    source => 'puppet:///modules/arnold/arnold.init',
    mode   => '0755',
  }

  service { 'arnold':
    ensure => running,
    enable => true,
  }
}