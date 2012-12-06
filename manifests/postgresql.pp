class continuum::postgresql(
  $user = 'continuum',
  $version = '9.0',
  $password,
  $db_password,
  $allowed_rules) {

  if $version != undef {
    yumrepo { 'postgresql-repo':
      name     => "postgresql-${version}",
      baseurl  => "http://yum.postgresql.org/${version}/redhat/rhel-\$releasever-\$basearch",
      descr    => "Postgresql ${version} Yum Repo",
      enabled  => 1,
      gpgcheck => 0,
      before => Class[postgresql::server],
    }
    class { 'postgresql::params':
      version             => $version,
      manage_package_repo => false,
      package_source      => 'yum.postgresql.org',
      before              => Class['postgresql::server'],
    }
  }

  class { 'postgresql::server':
    config_hash => {
      'ip_mask_deny_postgres_user' => '0.0.0.0/32',
      'ip_mask_allow_all_users'    => '0.0.0.0/0',
      'listen_addresses'           => '*',
      'manage_redhat_firewall'     => false,
      'postgres_password'          => $password,
      'ipv4acls'                   => $allowed_rules
     },
  }
  postgresql::db{ 'continuum':
    user => $user,
    password => $db_password,
  }  
}
