class continuum::postgresql(
  $user = 'continuum',
  $version = '9.0',
  $password,
  $db_password,
  $allowed_rules) {

  if $version != undef {
    class { 'postgresql::version':
      version => '9.0',
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
