class arnold::provisionator {
  File {
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['arnold'],
    notify  => Service['arnold'],
  }
  
  package { 'arnold':
    ensure   => present,
    provider => 'gem',
  }
  
  file { '/etc/arnold':
    ensure  => directory,
  }
  
  file { '/etc/arnold/config.yaml':
    ensure => file,
    source => 'puppet:///modules/arnold/config.yaml',
  }

  file { '/etc/arnold/certs':
    ensure  => directory,
    source  => 'puppet:///modules/arnold/certs',
    recurse => true,
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