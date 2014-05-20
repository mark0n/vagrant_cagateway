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

  apt::source { 'controls_repo':
    location    => 'http://35.9.58.138:8082/',
    release     => 'release-trunk',
    repos       => 'main',
    include_src => false,
    key         => 'BC54A6DE',
    key_source  => 'http://35.9.58.138:8082/repo_key.gpg',
  }

  package { 'epics-catools':
    ensure => installed,
    require => Apt::Source['controls_repo'],
  }

  class { 'epics_gateway':
    require => Apt::Source['controls_repo'],
  }

  file { '/epics':
    ensure => directory,
    owner  => root,
    mode   => '0755',
  }

  file { '/epics/cagateway_192.168.2.xxx':
    ensure => directory,
    owner  => root,
    mode   => '0755',
  }

  file { '/epics/cagateway_192.168.2.xxx/gateway2.pvlist':
    ensure => file,
    source => '/vagrant/files/epics/gateway_192.168.2.xxx/gateway2.pvlist',
    owner  => root,
    mode   => '0755',
  }

  file { '/epics/cagateway_192.168.2.xxx/gateway2.access':
    ensure => file,
    source => '/vagrant/files/epics/gateway_192.168.2.xxx/gateway2.access',
    owner  => root,
    mode   => '0755',
  }

  epics_gateway::gateway { '192.168.2.xxx':
    server_ip   => '192.168.2.2',
    client_ip   => '192.168.1.255',
    pv_list     => 'gateway2.pvlist',
    access_file => 'gateway2.access',
    subscribe => [
      File['/epics/cagateway_192.168.2.xxx/gateway2.pvlist'],
      File['/epics/cagateway_192.168.2.xxx/gateway2.access'],
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
    location    => 'http://epics.nsls2.bnl.gov/debian/',
    release     => 'wheezy',
    repos       => 'main contrib',
    include_src => false,
    key         => 'BE16DA67',
    key_source  => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
  }

  class { 'epics_softioc':
    iocbase => $iocbase,
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

  Apt::Source['nsls2repo'] -> Class['epics_softioc']
}

node 'client.example.com' {
  include apt

  host { 'gateway.example.com':
    ip           => '192.168.2.2',
    host_aliases => 'gateway',
  }

  apt::source { 'nsls2repo':
    location    => 'http://epics.nsls2.bnl.gov/debian/',
    release     => 'wheezy',
    repos       => 'main contrib',
    include_src => false,
    key         => '256355f9',
    key_source  => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
  }

  package { 'epics-catools':
    ensure  => installed,
    require => Apt::Source['nsls2repo'],
  }
}