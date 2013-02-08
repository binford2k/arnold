class arnold::provisionator {
  File {
    owner  => root,
    group  => root,
    mode   => '0644',
    notify => Service['arnold'],
  }
  file { '/usr/local/share/arnold':
    ensure => directory,
  }
  
   file { '/usr/local/share/arnold/public':
    ensure  => directory,
    source  => 'puppet:///modules/arnold/public',
    recurse => true,
  }

  file { '/usr/local/share/arnold/views':
    ensure  => directory,
    source  => 'puppet:///modules/arnold/views',
    recurse => true,
  }

  file { '/usr/local/share/arnold/arnold.rb':
    ensure => file,
    source => 'puppet:///modules/arnold/arnold.rb',
    mode   => '0755',
  }
  
  file { '/etc/arnold':
    ensure  => directory,
    source  => 'puppet:///modules/arnold/config',
    recurse => true,
    replace => false,
  }
  
  file { '/usr/local/bin/arnold':
    ensure => link,
    target => '/usr/local/share/arnold/arnold.rb',
  }
  
  file { '/etc/init.d/arnold':
    ensure => file,
    source => 'puppet:///modules/arnold/arnold.init',
    mode   => '0755',
    notify => undef,
  }
  
  service { 'arnold':
    ensure => running,
    enable => true,
  }
}