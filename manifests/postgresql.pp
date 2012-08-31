class continuum::postgresql(
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
  postgres::config { "host" :listen => "*" } ->
  postgres::enable { "host": require => Postgres::Config["host"], } ->
  postgres::user { "maestro": passwd => $db_password, } ->
  postgres::createdb { "maestro":owner=> "maestro", require => Postgres::Createuser["maestro"], } ->
  postgres::createdb { "luceedb":owner=> "maestro", require => Postgres::Createuser["maestro"], } ->
  postgres::createdb { "users":owner=> "maestro", require => Postgres::Createuser["maestro"], } ->
  postgres::createdb { "continuum":owner=> "maestro", require => Postgres::Createuser["maestro"], } ->
  postgres::createdb { "archiva":owner=> "maestro", require => Postgres::Createuser["maestro"], } ->
  postgres::createdb { "sonar":owner=> "maestro", require => Postgres::Createuser["maestro"], } 

}