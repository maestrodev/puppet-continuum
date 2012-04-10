require "#{File.join(File.dirname(__FILE__), '..', 'spec_helper')}"

PARAMS = {
    :version => '1.4.0'
}

describe 'continuum' do
  let(:params) { PARAMS }

  context "when user does not exist" do
    let(:params) { {
        :user => 'myuser'
    }.merge PARAMS }

    it { should contain_user('myuser') }
  end

  context "when downloading continuum" do
    it do
      should contain_wget__fetch('continuum_download').with(
                 'source' => 'http://archive.apache.org/dist/continuum/binaries/apache-continuum-1.4.0-bin.tar.gz',
                 'user' => nil,
                 'password' => nil
             )
    end
  end

  context "when downloading continuum from another repo" do
    let(:params) { {
        :repo => {
            'url' => 'http://repo1.maven.org/maven2',
            'username' => 'u',
            'password' => 'p'
        }
    }.merge PARAMS }

    it 'should fetch continuum with username and password' do
      should contain_wget__authfetch('continuum_download').with(
                 'source' => 'http://repo1.maven.org/maven2/org/apache/continuum/continuum-jetty/1.4.0/continuum-jetty-1.4.0-bin.tar.gz',
                 'user' => 'u',
                 'password' => 'p')
    end
  end
end
