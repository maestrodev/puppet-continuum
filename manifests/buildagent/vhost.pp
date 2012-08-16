define continuum::buildagent::vhost(
  $port = "8181",
  $installbase = "/var/local/$name",
  $workingdir = undef,
  $enabled = true,
  $master_host = "localhost",
  $master_port = "8080",
  $master_path = "/continuum/master-xmlrpc",
  $shared_secret_password = undef
) {

  if $workingdir == undef {
    $workingdir_real = "$installbase/data/working-directory"
  }
  else {
    $workingdir_real = $workingdir
  }

  if $shared_secret_password == undef {
    $shared_secret_password_real = $continuum::buildagent::shared_secret_password
  }
  else {
    $shared_secret_password_real = $shared_secret_password
  }

  File {
    owner => $continuum::buildagent::user,
    group => $continuum::buildagent::group,
  }

  file { "$installbase":
    ensure => directory,
  } ->
  file { "$installbase/tmp":
    ensure => directory,
  } ->
  file { "$installbase/logs":
    ensure => directory,
  } ->
  file { "$installbase/conf":
    ensure => directory,
  } ->
  file { "$installbase/conf/wrapper.conf": 
    ensure => present, 
    source => "$continuum::buildagent::installdir/conf/wrapper.conf", 
    require => Exec["continuum_buildagent_untar"]
  } ->
  file { "$installbase/conf/shared.xml": ensure  => present, source => "$continuum::buildagent::installdir/conf/shared.xml", } ->
  file { "$installbase/conf/jetty.xml":
    ensure  => present,
    content => template("continuum/buildagent/jetty.xml.erb"),
    notify  => Service[$name],
  } ->
  file { "$installbase/conf/continuum-buildagent.xml":
    content => template("continuum/buildagent/continuum-buildagent.xml.erb"),
    notify  => Service[$name],
  } ->
  file { "/etc/init.d/$name":
    owner   => "root",
    mode    => "0755",
    content => template("continuum/buildagent/continuum-buildagent.erb"),
  } ->
  service { $name:
      ensure => $enabled ? { true => running, false => stopped },
      enable => $enabled,
      hasrestart => true,
      hasstatus => true,
      subscribe => Exec[continuum_buildagent_untar],
      require => Package["java"],
  }
}

