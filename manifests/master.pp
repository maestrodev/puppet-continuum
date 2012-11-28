# Copyright 2012 MaestroDev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class continuum::master(
  $version = $continuum::params::version,
  $user = $continuum::params::user,
  $group = $continuum::params::group,
  $user_home = $continuum::params::user_home,
  $shared_secret_password = $continuum::params::shared_secret_password,
  $port = "8080",
  $service = "continuum",
  $installroot = "/usr/local",
  $installbase = "/var/local/continuum",
  $download_mirror = $continuum::params::download_mirror,
  $download_maven_repo = $continuum::params::download_maven_repo,
  $application_url = undef,
  $mail_from = {
    #name => "Apache Continuum",
    #address => "continuum@example.com",
  },
  $ldap = {
    #hostname => "",
    #ssl => true,
    #port => "636",
    #dn => "",
    #bind_dn => "",
    #bind_password => "",
    #admin_user => "root",
  },
  $cookie_path = "",
  $continuum_jdbc = {
    url => "jdbc:derby:/var/local/continuum/data/databases/continuum;create=true",
    driver => "org.apache.derby.jdbc.EmbeddedDriver",
    databaseName => "/var/local/continuum/data/databases/continuum",
    dataSource => "org.apache.derby.jdbc.EmbeddedDataSource",
    username => "SA",
    password => "",
  },
  $users_jdbc = {
    url => "jdbc:derby:/var/local/continuum/data/databases/users;create=true",
    driver => "org.apache.derby.jdbc.EmbeddedDriver",
    databaseName => "/var/local/continuum/data/databases/users",
    dataSource => "org.apache.derby.jdbc.EmbeddedDataSource",
    username => "SA",
    password => "",
  },
  $jdbc_driver_url = "",
  $jetty_version = undef,
  $forwarded = false,
) inherits continuum::params {

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  File { owner => $user, group => $group, mode => "0644" }
  Exec { path => "/bin" }

  $installdir = "$installroot/apache-continuum-$version"
  $archive = "/usr/local/src/apache-continuum-${version}-bin.tar.gz"

  if $jetty_version == undef {
    if $version =~ /(1\.[1-3]\..*|1\.4\.0|1\.4\.1-)/ {
      $jetty_version_real = 6
    } else {
      $jetty_version_real = 8
    }
  }
  else {
    $jetty_version_real = $jetty_version
  }

  if $application_url == undef {
    $application_url_real = "http://localhost:${port}/continuum"
  }
  else {
    $application_url_real = $application_url
  }

  if !defined(Group[$group]) {
    group { "$group":
      ensure  => present,
      system     => true,
    }
  }
  if !defined(User[$user]) {
    if $user_home == undef {
       $user_home_real = $installbase
    }
    else {
        $user_home_real = $user_home
    }
    user { "$user":
      ensure     => present,
      home       => $user_home_real,
      managehome => false,
      system     => true,
      gid        => $group,
    }
  }

  if "x${download_maven_repo['url']}x" != "xx" {
    wget::authfetch { "continuum_download":
      source => "${download_maven_repo['url']}/org/apache/continuum/continuum-jetty/$version/continuum-jetty-${version}-bin.tar.gz",
      destination => $archive,
      user => $download_maven_repo['username'],
      password => $download_maven_repo['password'],
      notify => Exec["continuum_untar"],
    }
  } else {
    wget::fetch { "continuum_download":
      source => "$download_mirror/continuum/binaries/apache-continuum-${version}-bin.tar.gz",
      destination => $archive,
      notify => Exec["continuum_untar"],
    }
  }
  exec { "continuum_untar":
    command => "tar zxf $archive",
    cwd     => "$installroot",
    creates => "$installdir",
    notify  => Service[$service],
  } ->
  file { "$installroot/$service":
    ensure  => link,
    target  => "$installdir",
  }
  if $::architecture == "x86_64" {
    file { "$installdir/bin/wrapper-linux-x86-32":
      ensure => absent,
      require => Exec["continuum_untar"],
    }
    file { "$installdir/lib/libwrapper-linux-x86-32.so":
      ensure => absent,
      require => Exec["continuum_untar"],
    }
  }
  if $jdbc_driver_url != "" {
    $filename = regsubst("$jdbc_driver_url","^.*/", "")
    wget::fetch { "continuum_jdbc_driver_download":
      source => "$jdbc_driver_url",
      destination => "$installdir/lib/$filename",
      require => Exec["continuum_untar"],
    } ->
    exec { "continuum_jdbc_driver_append":
      command => "sed -i 's/derby.*$/${filename}/' ${installdir}/conf/wrapper.conf",
      unless => "grep '${filename}' ${installdir}/conf/wrapper.conf",
      notify => Service[$service],
      before => File["$installbase/conf/wrapper.conf"],
    }
  }
  file { "$installbase":
    ensure => directory,
  }
  file { "$installbase/tmp":
    ensure => directory,
  }
  file { "$installbase/data":
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
    source => "$installdir/conf/wrapper.conf",
    require => Exec["continuum_untar"],
    notify  => Service[$service],
  }
  file { "$installbase/conf/shared.xml":
    ensure  => present,
    source => "$installdir/conf/shared.xml",
    require => Exec["continuum_untar"],
    notify  => Service[$service],
  }
  file { "$installbase/conf/security.properties":
    ensure  => present,
    content => template("continuum/security.properties.erb"),
    notify  => Service[$service],
  }
  file { "$installdir/apps/continuum/WEB-INF/classes/META-INF/plexus/application.xml":
    content =>  template("continuum/application.xml.erb"),
    require => Exec["continuum_untar"],
    notify  => Service[$service],
  }
  file { "$installbase/conf/continuum.xml":
    content => template("continuum/continuum.xml.erb"),
    replace => no,
    before  => Service[$service],
  }

  if $jetty_version_real == 6 {
    file { "$installbase/conf/jetty.xml":
      ensure  => present,
      content => template("continuum/jetty6.xml.erb"),
      notify  => Service[$service],
    }
  } else {
    file { "$installbase/conf/jetty.xml":
      ensure  => absent,
      notify  => Service[$service],
    }
    file { "$installdir/conf/jetty.xml":
      ensure  => present,
      content => template("continuum/jetty8.xml.erb"),
      notify  => Service[$service],
    }
    file { "$installbase/contexts":
      ensure  => directory,
    }
    file { "$installbase/contexts/continuum.xml":
      ensure  => present,
      content => template("continuum/contexts-continuum.xml.erb"),
      notify  => Service[$service],
    }
  }

  file { "/etc/profile.d/continuum.sh":
    owner   => "root",
    mode    => "0755",
    content => "export CONTINUUM_BASE=$installbase\n",
  } ->
  file { "/etc/init.d/$service":
    owner   => "root",
    mode    => "0755",
    content => template("continuum/continuum.erb"),
  } ->
  service { $service:
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    enable => true,
  }
}
