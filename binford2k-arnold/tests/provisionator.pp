class { 'arnold::provisionator':
  reusecerts => false,
  classes    => {
    'apache'      => 'Manage the Apache webserver'
    'mysql'       => 'Manage the MySQL database',
    'ntp::server' => 'Install the NTP server',
    'ntp::client' => 'Install the NTP client and configure the node to query the internal NTP server',
  },
}
