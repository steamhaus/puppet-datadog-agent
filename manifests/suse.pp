# Class: datadog_agent::suse
#
# This class contains the DataDog agent installation mechanism for SUSE distributions
#

class datadog_agent::suse(
  Integer $agent_major_version = $datadog_agent::params::default_agent_major_version,
  String $agent_version = $datadog_agent::params::agent_version,
  String $release = $datadog_agent::params::apt_default_release,
  Optional[String] $agent_repo_uri = undef,
) inherits datadog_agent::params {


  case $agent_major_version {
    5 : { fail('Agent v5 package not available in SUSE') }
    6 : {
      $repos = '6'
      $gpgkey = 'https://yum.datadoghq.com/DATADOG_RPM_KEY.public'
    }
    7 : {
      $repos = '7'
      $gpgkey = 'https://yum.datadoghq.com/DATADOG_RPM_KEY_E09422B3.public'
    }
    default: { fail('invalid agent_major_version') }
  }

  if ($agent_repo_uri != undef) {
    $baseurl = $agent_repo_uri
  } else {
    $baseurl = "https://yum.datadoghq.com/suse/${release}/${agent_major_version}/${::architecture}"
  }

  $public_key_local = '/tmp/DATADOG_RPM_KEY.public'

  file { 'DATADOG_RPM_KEY_E09422B3.public':
    owner  => root,
    group  => root,
    mode   => '0600',
    path   => $public_key_local,
    source => $gpgkey
  }

  exec { 'install-gpg-key':
    command => "/bin/rpm --import ${public_key_local}",
    onlyif  => "/usr/bin/gpg --dry-run --quiet --with-fingerprint -n ${public_key_local} | grep 'A4C0 B90D 7443 CF6E 4E8A  A341 F106 8E14 E094 22B3' || gpg --dry-run --import --import-options import-show ${public_key_local} | grep 'A4C0B90D7443CF6E4E8AA341F1068E14E09422B3'",
    unless  => '/bin/rpm -q gpg-pubkey-e09422b3',
    require => File['DATADOG_RPM_KEY_E09422B3.public'],
  }


  package { 'datadog-agent-base':
    ensure => absent,
    before => Package[$datadog_agent::params::package_name],
  }

  zypprepo { 'datadog':
    baseurl       => $baseurl,
    enabled       => 1,
    autorefresh   => 1,
    name          => 'datadog',
    gpgcheck      => 1,
    repo_gpgcheck => 0,
    gpgkey        => $gpgkey,
    keeppackages  => 1,
  }

  package { $datadog_agent::params::package_name:
    ensure  => $agent_version,
  }

}
