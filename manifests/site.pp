$vcsbase = '/usr/local/lib/flint'
$iocbase = "${vcsbase}/flint-ca"

host { 'gateway.example.com':
  ip           => '192.168.1.2',
  host_aliases => 'gateway',
}

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
    location    => 'http://epics.nsls2.bnl.gov/debian/',
    release     => 'wheezy',
    repos       => 'main contrib',
    include_src => false,
    key         => 'BE16DA67',
    key_source  => 'http://epics.nsls2.bnl.gov/debian/repo-key.pub',
  }

  package { 'epics-catools':
    ensure => installed,
  }

  package { 'build-essential':
    ensure => installed,
  }

  package { 'epics-dev':
    ensure => installed,
  }

  #  package { 'epics-cagateway':
#    ensure => installed,
#  }
  Apt::Source['nsls2repo'] -> Package <| |>
}

node 'testioc.example.com' {
  include apt

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