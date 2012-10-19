require "#{File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')}"

describe "continuum::buildagent::vhost" do
  let(:node) { "buildagent" }
  let(:title) { "continuum-buildagent-02" }
  let(:pre_condition) { %Q[
    class { 'continuum::buildagent':
      default_vhost => false,
    }
  ] }

  context "with defaults" do
    it { should contain_continuum__buildagent__vhost('continuum-buildagent-02') }
    it { should contain_service('continuum-buildagent-02') }
    it { should contain_file('/etc/init.d/continuum-buildagent-02') }

    it { should_not contain_continuum__buildagent__vhost('continuum-buildagent') }
    it { should_not contain_service('continuum-buildagent') }
    it { should_not contain_file('/etc/init.d/continuum-buildagent') }

    it "should generate a valid jetty.xml port" do
      content = catalogue.resource('file', '/var/local/continuum-buildagent-02/conf/jetty.xml').send(:parameters)[:content]
      content.should =~ /name="jetty.port" default="8181"/
    end

    it "should generate a valid init.d script" do
      content = catalogue.resource('file', '/etc/init.d/continuum-buildagent-02').send(:parameters)[:content]
      content.should =~ %r[^export HOME=/var/local/continuum-buildagent$]
      content.should =~ %r[^export RUN_AS_USER=continuum$]
      content.should =~ %r[^export CONTINUUM_BUILDAGENT_BASE=/var/local/continuum-buildagent-02$]
      content.should =~ %r[^APP_NAME="continuum-buildagent-02"$]
    end

    it "should generate a valid continuum-buildagent.xml file" do
      content = catalogue.resource('file', '/var/local/continuum-buildagent-02/conf/continuum-buildagent.xml').send(:parameters)[:content]
      content.should =~ %r[<continuumServerUrl>http://localhost:8080/continuum/master-xmlrpc</continuumServerUrl>]
      content.should =~ %r[<buildOutputDirectory>/var/local/continuum-buildagent-02/data/build-output-directory</buildOutputDirectory>]
      content.should =~ %r[<workingDirectory>/var/local/continuum-buildagent-02/data/working-directory</workingDirectory>]
      content.should_not =~ %r[<sharedSecretPassword>]
    end

    it { should contain_file('/var/local/continuum-buildagent-02/conf/wrapper.conf').with_source("/usr/local/apache-continuum-buildagent-#{CONTINUUM_VERSION}/conf/wrapper.conf") }
    it { should contain_file('/var/local/continuum-buildagent-02/conf/shared.xml').with_source("/usr/local/apache-continuum-buildagent-#{CONTINUUM_VERSION}/conf/shared.xml") }
    it { should contain_file('/var/local/continuum-buildagent-02').with_owner("continuum") }
  end

  context "with jetty 8" do
    let(:pre_condition) { %Q[
      class { 'continuum::buildagent':
        default_vhost => false,
        jetty_version => 8,
      }
    ] }

    it { should_not contain_file('/var/local/continuum-buildagent-02/conf/jetty.xml') }
    it { should contain_file('/var/local/continuum-buildagent-02/contexts/continuum-buildagent.xml') }
    it { should contain_file('/var/local/continuum-buildagent-02/conf/wrapper.conf').with_source("/usr/local/apache-continuum-buildagent-#{CONTINUUM_VERSION}/conf/wrapper.conf") }
    it { should_not contain_augeas('continuum-buildagent-02-set-jetty-port') }
  end

  context "with a different port" do
    let(:params) { {
        :port => "9999"
    } }

    it "should generate a valid jetty.xml port" do
      content = catalogue.resource('file', '/var/local/continuum-buildagent-02/conf/jetty.xml').send(:parameters)[:content]
      content.should =~ /name="jetty.port" default="9999"/
    end
  end

  context "with a different port and jetty 8" do
    let(:pre_condition) { %Q[
      class { 'continuum::buildagent':
        default_vhost => false,
        jetty_version => 8,
      }
    ] }
    let(:params) { {
        :port => "9999"
    } }

    it { should contain_file('/var/local/continuum-buildagent-02/conf/wrapper.conf').with_source("/usr/local/apache-continuum-buildagent-#{CONTINUUM_VERSION}/conf/wrapper.conf") }
    it { should contain_augeas('continuum-buildagent-02-set-jetty-port').with_changes('set wrapper.app.parameter.6 -Djetty.port=9999') }
  end

  context "with a different master" do
    let(:params) { {
        :master_port => "8888",
        :master_host => "continuum.example.com",
        :master_path => "/continuum/master-of-the-universe-xmlrpc"
    } }

    it "should generate a valid continuum-buildagent.xml file" do
      content = catalogue.resource('file', '/var/local/continuum-buildagent-02/conf/continuum-buildagent.xml').send(:parameters)[:content]
      content.should =~ %r[<continuumServerUrl>http://continuum.example.com:8888/continuum/master-of-the-universe-xmlrpc</continuumServerUrl>]
    end
  end

  context "with a shared secret password" do
    let(:params) { {
        :shared_secret_password => "kensentme",
    } }

    it "should generate a valid continuum-buildagent.xml file" do
      content = catalogue.resource('file', '/var/local/continuum-buildagent-02/conf/continuum-buildagent.xml').send(:parameters)[:content]
      content.should =~ %r[<sharedSecretPassword>kensentme</sharedSecretPassword>]
    end
  end
end


