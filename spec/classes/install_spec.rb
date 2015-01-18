require 'spec_helper'

describe 'islandora' do

  context 'On a Redhat OS' do

    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystemrelease => '6.4',
        :concat_basedir => '/var/lib/puppet'
      }
    end

    # @todo Resolve
    # it { should compile }
    # it { should compile.with_all_deps }

    # For the Drush installation process
    it { should create_class('drush')}

    it do

      should contain_drush__exec('islandora_deploy')
        .that_requires("Drush::Exec[islandora_drupal_install]")
        .that_requires("Postgresql::Server::Db[islandora]")
    end

    it { should create_class('postgresql::server')}

    it { should create_class('apache')}

    it { should have_firewall_resource_count(1) }

  end
end
