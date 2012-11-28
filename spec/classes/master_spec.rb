require "#{File.join(File.dirname(__FILE__), '..', 'spec_helper')}"

MAIL_FROM = {
    'name' => "Brett Porter",
    'address' => "brett@apache.org"
}

describe 'continuum::master' do
  context "when defaults" do
    it { should contain_group('continuum') }
    it { should contain_user('continuum').with(:home => '/var/local/continuum', :gid => 'continuum') }
    it { should contain_class('continuum::master') }
    it { should contain_service('continuum') }
    it { should contain_file("/usr/local/continuum").with_target("/usr/local/apache-continuum-#{CONTINUUM_VERSION}") }

    it "should generate a valid jetty.xml port" do
      content = catalogue.resource('file', '/var/local/continuum/conf/jetty.xml').send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-jetty.xml", File.dirname(__FILE__)))
    end

    it "should generate a valid security.properties file" do
      content = catalogue.resource('file', '/var/local/continuum/conf/security.properties').send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-security.properties", File.dirname(__FILE__)))
    end

    it "should generate a valid init.d script" do
      content = catalogue.resource('file', '/etc/init.d/continuum').send(:parameters)[:content]
      content.should =~ %r[^\. /etc/profile.d/continuum.sh$]
      content.should =~ %r[^RUN_AS_USER=continuum$]
      content.should =~ %r[WRAPPER_CMD="/usr/local/continuum/bin/wrapper"$]
    end

    it "should generate a valid continuum.xml file" do
      content = catalogue.resource('file', '/var/local/continuum/conf/continuum.xml').send(:parameters)[:content]
      content.should =~ %r[<baseUrl>http://localhost:8080/continuum</baseUrl>]
      content.should =~ %r[<buildOutputDirectory>/var/local/continuum/data/build-output-directory</buildOutputDirectory>]
      content.should =~ %r[<releaseOutputDirectory>/var/local/continuum/data/release-output-directory</releaseOutputDirectory>]
      content.should =~ %r[<workingDirectory>/var/local/continuum/data/working-directory</workingDirectory>]
      content.should_not =~ %r[<sharedSecretPassword>]
      content.should_not =~ %r[<distributedBuildEnabled>true</distributedBuildEnabled]
    end

    it "should generate a valid application.xml file" do
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/apps/continuum/WEB-INF/classes/META-INF/plexus/application.xml").send(:parameters)[:content]
      content.should =~ %r[<from-mailbox></from-mailbox>]
      content.should =~ %r[<from-name></from-name>]
    end

    it { should contain_file('/var/local/continuum/conf/wrapper.conf').with_source("/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/wrapper.conf") }
    it { should contain_file('/var/local/continuum/conf/shared.xml').with_source("/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/shared.xml") }
  end

  context "when using jetty 8" do
    let(:params) { {
        :jetty_version => 8,
    } }
    it "should generate a valid jetty.xml" do
      should contain_file('/var/local/continuum/conf/jetty.xml').with_ensure('absent')
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/jetty.xml").send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-jetty-8.xml", File.dirname(__FILE__)))
      content.should_not =~ %r[<Set name="forwarded">true</Set>]
    end

    it "should populate jetty context" do
      content = catalogue.resource('file', '/var/local/continuum/contexts/continuum.xml').send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-context.xml", File.dirname(__FILE__)))
    end
  end

  context "when port changes" do
    let(:params) { {
        :port => "9999"
    } }
    it "should generate a valid jetty.xml port" do
      content = catalogue.resource('file', '/var/local/continuum/conf/jetty.xml').send(:parameters)[:content]
      content.should =~ /name="jetty.port" default="9999"/
    end

    it "should generate a valid continuum.xml file with right port" do
      content = catalogue.resource('file', '/var/local/continuum/conf/continuum.xml').send(:parameters)[:content]
      content.should =~ %r[<baseUrl>http://localhost:9999/continuum</baseUrl>]
    end

    it "should generate a valid security.properties file with right port" do
      content = catalogue.resource('file', '/var/local/continuum/conf/security.properties').send(:parameters)[:content]
      content.should =~ %r[application.url = http://localhost:9999/continuum]
    end
  end

  context "when port changes on jetty 8" do
    let(:params) { {
        :port => "9999",
        :jetty_version => 8,
    } }
    it "should generate a valid jetty.xml port" do
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/jetty.xml").send(:parameters)[:content]
      content.should =~ /name="jetty.port" default="9999"/
    end
  end

  context "when ssl forwarding on jetty 8" do
    let(:params) { {
        :forwarded => true,
        :jetty_version => 8,
    } }
    it "should set forwarded" do
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/jetty.xml").send(:parameters)[:content]
      content.should =~ %r[<Set name="forwarded">true</Set>]
    end
  end

  context "when mail_from set" do
    let(:params) { {
        :mail_from => MAIL_FROM
    } }

    it "should generate a valid security.properties file with properties" do
      content = catalogue.resource('file', '/var/local/continuum/conf/security.properties').send(:parameters)[:content]
      content.should =~ %r[email.from.address = brett@apache.org]
      content.should =~ %r[email.from.name = Brett Porter]
    end

    it "should generate a valid application.xml file" do
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/apps/continuum/WEB-INF/classes/META-INF/plexus/application.xml").send(:parameters)[:content]
      content.should =~ %r[<from-mailbox>brett@apache.org</from-mailbox>]
      content.should =~ %r[<from-name>Brett Porter</from-name>]
    end

  end

  context "when user does not exist" do
    let(:params) { {
        :user => 'myuser',
        :group => 'myuser'
    } }

    it { should contain_group('myuser') }
    it { should contain_user('myuser').with(:home => '/var/local/continuum', :gid => 'myuser') }

    it "should generate a valid init.d script" do
      content = catalogue.resource('file', '/etc/init.d/continuum').send(:parameters)[:content]
      content.should =~ %r[^RUN_AS_USER=myuser$]
    end
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
      should contain_wget__fetch('continuum_download').with(
                 'source' => "http://archive.apache.org/dist/continuum/binaries/apache-continuum-#{CONTINUUM_VERSION}-bin.tar.gz",
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
      should contain_wget__fetch('continuum_download').with(
                 'source' => "http://mirror.aarnet.edu.au/pub/apache/continuum/binaries/apache-continuum-#{CONTINUUM_VERSION}-bin.tar.gz",
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
      should contain_wget__authfetch('continuum_download').with(
                 'source' => "http://repo1.maven.org/maven2/org/apache/continuum/continuum-jetty/#{CONTINUUM_VERSION}/continuum-jetty-#{CONTINUUM_VERSION}-bin.tar.gz",
                 'user' => 'u',
                 'password' => 'p')
    end
  end

  context "with custom version" do
    let(:params) { {
        :version => "1.2.3.4.5"
    } }

    it { should contain_file("/usr/local/continuum").with_target("/usr/local/apache-continuum-1.2.3.4.5") }
    it { should contain_wget__fetch('continuum_download').with(
                    :source => 'http://archive.apache.org/dist/continuum/binaries/apache-continuum-1.2.3.4.5-bin.tar.gz',
                    :destination => "/usr/local/src/apache-continuum-1.2.3.4.5-bin.tar.gz") }
  end

  context "with postgres JDBC driver" do
    let(:params) {{
        :jdbc_driver_url => "http://driver.com/example.jar"
    }}

    it "should download JDBC driver" do
      should contain_wget__fetch("continuum_jdbc_driver_download")
      params = catalogue.resource('wget::fetch', "continuum_jdbc_driver_download").send(:parameters)
      params[:destination].should eq("/usr/local/apache-continuum-1.4.0/lib/example.jar")

      should contain_exec("continuum_jdbc_driver_append")
    end
  end

  context "with postgres jdbc settings" do
    let(:params) {{
      :continuum_jdbc => {
        'databaseName' => 'continuum',
        'dataSource'   => 'org.postgresql.ds.PGPoolingDataSource',
        'username'     => 'continuum_u',
        'password'     => 'continuum_p',
      },
      :users_jdbc => {
        'databaseName' => 'users',
        'dataSource'   => 'org.postgresql.ds.PGPoolingDataSource',
        'username'     => 'continuum_u',
        'password'     => 'continuum_p',
      },
    }}
    it "should populate jetty jdbc settings" do
      content = catalogue.resource('file', '/var/local/continuum/conf/jetty.xml').send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-postgres-jetty.xml", File.dirname(__FILE__)))
    end
  end

  context "with postgres JDBC settings and Jetty 8" do
    let(:params) {{
      :jetty_version => 8,
      :continuum_jdbc => {
        'url'         => 'jdbc:postgres://localhost/continuum',
        'driver'      => 'org.postgresql.Driver',
        'username'    => 'continuum_u',
        'password'    => 'continuum_p',
      },
      :users_jdbc => {
        'url'         => 'jdbc:postgres://localhost/users',
        'driver'      => 'org.postgresql.Driver',
        'username'    => 'continuum_u',
        'password'    => 'continuum_p',
      },
    }}

    it "should populate jetty context" do
      content = catalogue.resource('file', "/usr/local/apache-continuum-#{CONTINUUM_VERSION}/conf/jetty.xml").send(:parameters)[:content]
      content.should_not =~ %r[jdbc/continuum]
      content.should_not =~ %r[jdbc/users]

      content = catalogue.resource('file', '/var/local/continuum/contexts/continuum.xml').send(:parameters)[:content]
      content.should == IO.read(File.expand_path("expected-master-postgres-context.xml", File.dirname(__FILE__)))
    end
  end

  context "when cookie path is set" do
    let(:params) { { :cookie_path => "/" } }

    security_config_file="/var/local/continuum/conf/security.properties"
    it "should set the cookie paths" do
      should contain_file(security_config_file)
      content = catalogue.resource('file', security_config_file).send(:parameters)[:content]
      content.should =~ %r[security\.signon\.path=/]
      content.should =~ %r[security\.rememberme\.path=/]
    end
  end

  context "when cookie path is not set" do
    security_config_file="/var/local/continuum/conf/security.properties"
    it "should not set the cookie paths" do
      should contain_file(security_config_file)
      content = catalogue.resource('file', security_config_file).send(:parameters)[:content]
      content.should_not =~ %r[security\.signon\.path]
      content.should_not =~ %r[security\.rememberme\.path]
    end
  end

  context "when using 1.3.7" do
    let(:params) {{ :version => "1.3.7" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.4.0" do
    let(:params) {{ :version => "1.4.0" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.4.1-SNAPSHOT" do
    let(:params) {{ :version => "1.4.1-SNAPSHOT" }}
    it "should use jetty 6" do
      should_not contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.4.1" do
    let(:params) {{ :version => "1.4.1" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.4.2-SNAPSHOT" do
    let(:params) {{ :version => "1.4.2-SNAPSHOT" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.4.2" do
    let(:params) {{ :version => "1.4.2" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum/contexts')
    end
  end

  context "when using 1.5.0" do
    let(:params) {{ :version => "1.5.0" }}
    it "should use jetty 8" do
      should contain_file('/var/local/continuum/contexts')
    end
  end
end
