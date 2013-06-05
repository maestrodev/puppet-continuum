class { continuum:
  version => "1.4.1",
  # download_maven_repo => {
  #   url => "http://10.0.2.2:7777/archiva/repository/releases",
  #   username => "",
  #   password => "",
  # },
  shared_secret_password => "scary",
}

class { continuum::master:  }
class { continuum::buildagent: }
continuum::buildagent::vhost { "continuum-buildagent-02":
  port => 8182
}
