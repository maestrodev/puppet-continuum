node default {
}

node buildagent {
  class { continuum::buildagent:
    default_vhost => false,
  }
}
