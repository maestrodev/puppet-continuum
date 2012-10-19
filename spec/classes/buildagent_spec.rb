require "#{File.join(File.dirname(__FILE__), '..', 'spec_helper')}"

describe 'continuum::buildagent' do
  context "when defaults" do
    it { should contain_group('continuum') }
    it { should contain_user('continuum').with(:home => '/var/local/continuum-buildagent', :gid => 'continuum') }
    it { should contain_class('continuum::buildagent') }
    it { should contain_service('continuum-buildagent') }
    it { should contain_file("/usr/local/continuum-buildagent").with_target("/usr/local/apache-continuum-buildagent-#{CONTINUUM_VERSION}") }
  end

  context "when user does not exist" do
    let(:params) { {
        :user => 'myuser',
        :group => 'myuser'
    } }

    it { should contain_group('myuser') }
    it { should contain_user('myuser').with(:home => '/var/local/continuum-buildagent', :gid => 'myuser') }
  end

  context "when custom user home directory" do
    let(:params) { {
        :user_home => "/home/continuum"
    } }
    it { should contain_group('continuum') }
    it { should contain_user('continuum').with(:home => '/home/continuum', :gid => 'continuum') }
  end

  context "when downloading continuum from the default mirror" do
    it do
      should contain_wget__fetch('continuum_buildagent_download').with(
                 'source' => "http://archive.apache.org/dist/continuum/binaries/apache-continuum-buildagent-#{CONTINUUM_VERSION}-bin.tar.gz",
                 'user' => nil,
                 'password' => nil
             )
    end
  end

  context "when downloading continuum from a mirror" do
    let(:params) { {
        :download_mirror => "http://mirror.aarnet.edu.au/pub/apache"
    } }
    it do
      should contain_wget__fetch('continuum_buildagent_download').with(
                 'source' => "http://mirror.aarnet.edu.au/pub/apache/continuum/binaries/apache-continuum-buildagent-#{CONTINUUM_VERSION}-bin.tar.gz",
                 'user' => nil,
                 'password' => nil
             )
    end
  end

  context "when downloading continuum from a Maven repo" do
    let(:params) { {
        :download_maven_repo => {
            'url' => 'http://repo1.maven.org/maven2',
            'username' => 'u',
            'password' => 'p'
        }
    } }

    it 'should fetch continuum with username and password' do
      should contain_wget__authfetch('continuum_buildagent_download').with(
                 'source' => "http://repo1.maven.org/maven2/org/apache/continuum/continuum-buildagent-jetty/#{CONTINUUM_VERSION}/continuum-buildagent-jetty-#{CONTINUUM_VERSION}-bin.tar.gz",
                 'user' => 'u',
                 'password' => 'p')
    end
  end

  context "with custom version" do
    let(:params) { {
        :version => "1.2.3.4.5"
    } }

    it { should contain_wget__fetch('continuum_buildagent_download').with(
                    :source => 'http://archive.apache.org/dist/continuum/binaries/apache-continuum-buildagent-1.2.3.4.5-bin.tar.gz',
                    :destination => "/usr/local/src/apache-continuum-buildagent-1.2.3.4.5-bin.tar.gz") }
  end

  context "with default vhost" do
    it { should contain_file("/var/local/continuum-buildagent") }
  end

  context "with default vhost disabled" do
    let(:params) { {
        :default_vhost => false
    } }

    it { should_not contain_file("/var/local/continuum-buildagent") }
  end

  context "when using 1.3.7" do
    let(:params) {{ :version => "1.3.7" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.4.0" do
    let(:params) {{ :version => "1.4.0" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.4.1-SNAPSHOT" do
    let(:params) {{ :version => "1.4.1-SNAPSHOT" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.4.1" do
    let(:params) {{ :version => "1.4.1" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.4.2-SNAPSHOT" do
    let(:params) {{ :version => "1.4.2-SNAPSHOT" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.4.2" do
    let(:params) {{ :version => "1.4.2" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum-buildagent/contexts')
    end
  end

  context "when using 1.5.0" do
    let(:params) {{ :version => "1.5.0" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum-buildagent/contexts')
    end
  end
end
