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

class continuum::buildagent(
  $version = $continuum::params::version,
  $user = $continuum::params::user,
  $group = $continuum::params::group,
  $user_home = $continuum::params::user_home,
  $shared_secret_password = $continuum::params::shared_secret_password,
  $port = "8080",
  $installroot = "/usr/local",
  $installbase = "/var/local/continuum-buildagent",
  $download_mirror = $continuum::params::download_mirror,
  $download_maven_repo = $continuum::params::download_maven_repo,
  $default_vhost = true
) inherits continuum::params {

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  File { owner => $user, group => $group, mode => "0644" }
  Exec { path => "/bin" }

  $installdir = "$installroot/apache-continuum-buildagent-$version"
  $archive = "/usr/local/src/apache-continuum-buildagent-${version}-bin.tar.gz"

  if $user_home == undef {
   $user_home_real = $installbase
  }
  else {
    $user_home_real = $user_home
  }

  if !defined(Group[$group]) {
    group { "$group":
      ensure  => present,
      system     => true,
    }
  }
  if !defined(User[$user]) {
    user { "$user":
      ensure     => present,
      home       => $user_home_real,
      managehome => false,
      system     => true,
      gid        => $group,
    }
  }

  if "x${download_maven_repo['url']}x" != "xx" {
    wget::authfetch { "continuum_buildagent_download":
      source => "${download_maven_repo['url']}/org/apache/continuum/continuum-buildagent-jetty/$version/continuum-buildagent-jetty-${version}-bin.tar.gz",
      destination => $archive,
      user => $download_maven_repo['username'],
      password => $download_maven_repo['password'],
      notify => Exec["continuum_buildagent_untar"],
    }
  } else {
    wget::fetch { "continuum_buildagent_download":
      source => "$download_mirror/continuum/binaries/apache-continuum-buildagent-${version}-bin.tar.gz",
      destination => $archive,
      notify => Exec["continuum_buildagent_untar"],
    }
  }
  exec { "continuum_buildagent_untar":
    command => "tar zxf $archive",
    cwd     => "$installroot",
    creates => "$installdir",
  } ->
  file { "$installroot/continuum-buildagent":
    ensure  => link,
    target  => "$installdir",
  }
  if $::architecture == "x86_64" {
    file { "$installdir/bin/wrapper-linux-x86-32":
      ensure => absent,
      require => Exec["continuum_buildagent_untar"],
    }
    file { "$installdir/lib/libwrapper-linux-x86-32.so":
      ensure => absent,
      require => Exec["continuum_buildagent_untar"],
    }
  }

  if $default_vhost {
    continuum::buildagent::vhost { "continuum-buildagent":

	require => File["$installroot/continuum-buildagent"], 

    }
  }

  file { "/etc/facts.d":
    ensure => directory,
  } ->
  file { "/etc/facts.d/continuum.json":
    content  => template("continuum/buildagent/continuum.json.erb"),
  }
}
