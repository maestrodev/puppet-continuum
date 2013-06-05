# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "CentOS-6.4-x86_64-minimal"

  config.vm.synced_folder "/Users/csanchez/dev/maestrodev/puppet/continuum", "/etc/puppet/modules/continuum"
  config.vm.synced_folder "spec/fixtures/modules/wget", "/etc/puppet/modules/wget"
  config.vm.synced_folder "spec/fixtures/modules/maven", "/etc/puppet/modules/maven"

  config.vm.network :forwarded_port, guest: 8080, host: 8080

  # install the java module
  config.vm.provision :shell, :inline => "test -d /etc/puppet/modules/java || puppet module install puppetlabs/java -v 0.3.0"

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "vagrant/manifests"
    puppet.manifest_file  = "site.pp"
  end

end
