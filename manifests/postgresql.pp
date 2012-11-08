class continuum::postgresql(
  $user = 'continuum',
  $version = '90',
  $password,
  $db_password,
  $allowed_rules,
  $datadir) {

  class { 'postgres' :
    version  => $version,
    password => $password,
    datadir  => $datadir,
  }

  postgres::user { "postgres": passwd => $password, }

  postgres::initdb{ "host":
    require => Package["postgresql${version}"],
  } ->
  postgres::hba { "host": allowedrules => $allowed_rules } ->
  postgres::config { "host": listen => "*" } ->
  postgres::enable { "host": } ->
  postgres::user { $user: passwd => $db_password, } ->
  postgres::createdb { "continuum": owner=> $user }
}
