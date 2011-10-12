# Copyright 2011 MaestroDev
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

class continuum($version, $user = "continuum", $group = "continuum", $service =
  "continuum", $installroot = "/usr/local", $home = "/var/local/continuum",
  $apache_mirror = "http://archive.apache.org/dist/",
  $repo = {
    #url = "http://repo1.maven.org/maven2",
    #username = "",
    #password = "",
  },
  $port = "8080", $application_url = "http://localhost:8080/continuum",
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
  $continuum_jdbc = {
    url => "jdbc:derby:/var/local/continuum/data/databases/continuum;create=true",
    driver => "org.apache.derby.jdbc.EmbeddedDriver",
    username => "sa",
    password => "",
  },
  $users_jdbc = {
    url => "jdbc:derby:/var/local/continuum/data/databases/users;create=true",
    driver => "org.apache.derby.jdbc.EmbeddedDriver",
    username => "sa",
    password => "",
  },
  $jdbc_driver_url = "") {

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  File { owner => $user, group => $group, mode => "0644" }
  Exec { path => "/bin" }

  $installdir = "$installroot/apache-continuum-$version"
  $archive = "/usr/local/src/apache-continuum-${version}-bin.tar.gz"

  # Derby specifics
  if $continuum_jdbc['driver'] == "org.apache.derby.jdbc.EmbeddedDriver" {
    $continuum_u = regsubst($continuum_jdbc['url'],";.*$", "")
    $continuum_jdbc['shutdown_url'] = "$continuum_u;shutdown=true"
  }

  if $users_jdbc['driver'] == "org.apache.derby.jdbc.EmbeddedDriver" {
    $users_u = regsubst($users_jdbc['url'],";.*$", "")
    $users_jdbc['shutdown_url'] = "$users_u;shutdown=true"
  }

  user { "$user":
    ensure     => present,
    home       => "$home",
    managehome => false,
    system     => true,
  }
  group { "$group":
    ensure  => present,
    require => User["$user"],
  }
  if "x${repo['url']}x" != "xx" {
    wget::authfetch { "continuum_download":
      source => "${repo['url']}/org/apache/continuum/continuum-jetty/$version/continuum-jetty-${version}-bin.tar.gz",
      destination => $archive,
      user => $repo['username'],
      password => $repo['password'],
      notify => Exec["continuum_untar"],
    }
  } else {
    wget::fetch { "continuum_download":
      source => "$apache_mirror/continuum/binaries/apache-continuum-${version}-bin.tar.gz",
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
    wget::fetch { "jdbc_driver_download":
      source => "$jdbc_driver_url",
      destination => "$installdir/lib/$filename",
      require => Exec["continuum_untar"],
    } ->
    exec { "jdbc_driver_append":
      command => "sed -i 's#^wrapper.java.classpath.14=.*$#wrapper.java.classpath.14=%REPO_DIR%/$filename#' $installdir/conf/wrapper.conf",
      unless => "grep 'wrapper.java.classpath.14=%REPO_DIR%/$filename' $installdir/conf/wrapper.conf",
      notify => Service[$service],
    }
  }
  file { "$home":
    ensure => directory,
    recurse => true,
  } ->
  file { "$home/tmp":
    ensure => directory,
  } ->
  file { "$home/logs":
    ensure => directory,
  } ->
  file { "$home/conf":
    ensure => directory,
    require => Exec["continuum_untar"],
  } ->
  file { "$home/conf/wrapper.conf": ensure => link, target => "$installdir/conf/wrapper.conf", } ->
  file { "$home/conf/shared.xml": ensure  => present, source => "$installdir/conf/shared.xml", } ->
  file { "$home/conf/jetty.xml":
    ensure  => present,
    content => template("continuum/jetty.xml.erb"),
    notify  => Service[$service],
  } ->
  file { "$home/conf/security.properties":
    ensure  => present,
    content => template("continuum/security.properties.erb"),
    notify  => Service[$service],
  } ->
  file { "$home/apps/continuum/WEB-INF/classes/META-INF/plexus/application.xml":
    content =>  template("continuum/application.xml.erb"),
    notify  => Service[$service],
  } ->
  file { "/etc/profile.d/continuum.sh":
    owner   => "root",
    mode    => "0755",
    content => "export CONTINUUM_BASE=$home\n",
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
