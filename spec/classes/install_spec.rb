require 'spec_helper'

describe 'islandora' do

  let(:title) { 'test_islandora' }



  context 'On a Redhat OS' do

    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystemrelease => '6.4',
        :concat_basedir => '/var/lib/puppet'
      }
    end

    it { should compile }
  
    it do
    
      should contain_file('/usr/local/fedora/server/config/jaas.conf')
        .with_content(/DrupalAuthModule/)
    end

    it do

      should contain_file('/usr/local/fedora/server/config/filter-drupal.xml')
        .with({
                'ensure' => 'present',
                'owner' => 'tomcat',
                'group' => 'tomcat'
              })
    end
  end
end
