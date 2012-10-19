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
  }
  file { "$installbase/tmp":
    ensure => directory,
  }
  file { "$installbase/logs":
    ensure => directory,
  }
  file { "$installbase/conf":
    ensure => directory,
  }
  file { "$installbase/conf/wrapper.conf": 
    ensure => present, 
    source => "$continuum::buildagent::installdir/conf/wrapper.conf", 
    require => Exec["continuum_buildagent_untar"]
  }
  file { "$installbase/conf/shared.xml": 
    ensure  => present, 
    source => "$continuum::buildagent::installdir/conf/shared.xml", 
    require => Exec["continuum_buildagent_untar"]
  }
  file { "$installbase/conf/continuum-buildagent.xml":
    content => template("continuum/buildagent/continuum-buildagent.xml.erb"),
    notify  => Service[$name],
  }

  if $continuum::buildagent::jetty_version_real == 6 {
    file { "$installbase/conf/jetty.xml":
      ensure  => present,
      content => template("continuum/buildagent/jetty6.xml.erb"),
      notify  => Service[$name],
    }
  } else {
    file { "$installbase/contexts":
      ensure  => directory,
    }
    file { "$installbase/contexts/continuum-buildagent.xml":
      ensure  => present,
      content => template("continuum/buildagent/contexts-continuum-buildagent.xml.erb"),
      notify  => Service[$name],
    }

    if $port != "8181" {
      # Until Augeas has the properties files fixes, use a custom version
      # Just a basic approach - for more complete management of lenses consider https://github.com/camptocamp/puppet-augeas
      if !defined(File["/tmp/augeas"]) {
        file { "/tmp/augeas": ensure => directory }
      }
      file { "/tmp/augeas/continuum": ensure => directory } ->
      wget::fetch { "fetch-augeas-continuum":
        source => "https://raw.github.com/maestrodev/augeas/af585c7e29560306f23938b3ba15aa1104951f7f/lenses/properties.aug",
        destination => "/tmp/augeas/continuum/properties.aug",
      } ->

      # Adjust wrapper.conf
      augeas { "$name-set-jetty-port":
        lens => "Properties.lns",
        incl => "$installbase/conf/wrapper.conf",
        changes => "set wrapper.app.parameter.6 -Djetty.port=$port",
        load_path => "/tmp/augeas/archiva",
        require => File["${installbase}/conf/wrapper.conf"],
      }
    }
  }

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

