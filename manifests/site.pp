$vcsbase = '/usr/local/lib/flint'
$iocbase = "${vcsbase}/flint-ca"

host { 'testioc.example.com':
  ip           => '192.168.1.3',
  host_aliases => 'testioc',
}

host { 'client.example.com':
  ip           => '192.168.2.3',
  host_aliases => 'client',
}

node 'gateway.example.com' {
  include apt

  apt::source { 'nsls2repo':
    location => 'http://epics.nsls2.bnl.gov/debian/',
    release  => 'wheezy',
    repos    => 'main contrib',
    include  => {
      'src' => false,
    },
    key      => {
      'id'     => '97D2B6FC0D3BCB4ABC56679C11B01C94D1BE1726',
      'source' => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
    },
  }

  package { 'epics-catools':
    ensure  => installed,
    require => [
      Apt::Source['nsls2repo'],
      Class['apt::update'],
    ],
  }

  package { 'ioclogserver':
    ensure => installed,
    require => [
      Apt::Source['nsls2repo'],
      Class['apt::update'],
    ],
  }

  class { 'epics_gateway':
    require => [
      Apt::Source['nsls2repo'],
      Class['apt::update'],
    ],
  }

  file { '/etc/epics':
    ensure => directory,
    owner  => root,
    mode   => '0755',
  }

  # on production machines this directory might be under revision control
  file { '/etc/epics/cagateway-192.168.2.xxx':
    ensure  => directory,
    source  => '/vagrant/files/etc/epics/cagateway-192.168.2.xxx',
    recurse => true,
    owner   => root,
    mode    => '0755',
  }

  epics_gateway::gateway { '192.168.2.xxx':
    server_ip => '192.168.2.2',
    client_ip => '192.168.1.255',
    caputlog  => true,
    require   => Package['ioclogserver'],
    subscribe => [
      File['/etc/epics/cagateway-192.168.2.xxx'],
    ],
  }
}

node 'testioc.example.com' {
  include apt

  host { 'gateway.example.com':
    ip           => '192.168.1.2',
    host_aliases => 'gateway',
  }

  apt::source { 'nsls2repo':
    location => 'http://epics.nsls2.bnl.gov/debian/',
    release  => 'wheezy',
    repos    => 'main contrib',
    include  => {
      'src' => false,
    },
    key      => {
      'id'     => '97D2B6FC0D3BCB4ABC56679C11B01C94D1BE1726',
      'source' => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
    },
  }

  class { 'epics_softioc':
    iocbase => $iocbase,
    require => [
      Apt::Source['nsls2repo'],
      Class['apt::update'],
    ],
  }

  package { 'git':
    ensure => installed,
  }

  vcsrepo { $vcsbase:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/diirt/flint.git',
    require  => Package['git'],
  }

  file { "${iocbase}/control":
    ensure  => link,
    target  => "${vcsbase}/flint-controller/control",
    require => Vcsrepo[$vcsbase],
  }

  epics_softioc::ioc { 'control':
    ensure      => running,
    bootdir     => '',
    consolePort => '4051',
    enable      => true,
    require     => File["${vcsbase}/flint-ca/control"],
    subscribe   => Vcsrepo[$vcsbase],
  }

  file { '/etc/init.d/testcontroller':
    source  => '/vagrant/files/etc/init.d/testcontroller',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Vcsrepo[$vcsbase],
  }

  service { 'testcontroller':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => File['/etc/init.d/testcontroller'],
  }

  epics_softioc::ioc { 'phase1':
    bootdir     => '',
    consolePort => '4053',
    enable      => false,
    require     => Vcsrepo[$vcsbase],
    subscribe   => Vcsrepo[$vcsbase],
  }

  epics_softioc::ioc { 'typeChange1':
    bootdir     => '',
    consolePort => '4053',
    enable      => false,
    require     => Vcsrepo[$vcsbase],
    subscribe   => Vcsrepo[$vcsbase],
  }

  epics_softioc::ioc { 'typeChange2':
    bootdir     => '',
    consolePort => '4053',
    enable      => false,
    require     => Vcsrepo[$vcsbase],
    subscribe   => Vcsrepo[$vcsbase],
  }
}

node 'client.example.com' {
  include apt

  host { 'gateway.example.com':
    ip           => '192.168.2.2',
    host_aliases => 'gateway',
  }

  apt::source { 'nsls2repo':
    location => 'http://epics.nsls2.bnl.gov/debian/',
    release  => 'wheezy',
    repos    => 'main contrib',
    include  => {
      'src' => false,
    },
    key      => {
      'id'     => '97D2B6FC0D3BCB4ABC56679C11B01C94D1BE1726',
      'source' => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
    },
  }

  package { 'epics-catools':
    ensure  => installed,
    require => [
      Apt::Source['nsls2repo'],
      Class['apt::update'],
    ],
  }
}