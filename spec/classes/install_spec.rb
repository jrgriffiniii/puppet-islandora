require 'spec_helper'

describe 'islandora' do

  context 'on CentOS 6.4' do

    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'CentOS',
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

      should contain_file('/var/www/islandora-7.x-1.4')
        .with_ensure('absent')
        .with_force(true)
      
    end

    it do

      should contain_drush__exec('islandora_drupal_install')
        .that_requires("File[/var/www/islandora-7.x-1.4]")
        .that_requires("Exec[islandora_drush_env]")
        .that_requires("File[/tmp/islandora.make]")
    end

    it do

      should contain_drush__exec('islandora_deploy')
        .that_requires("Drush::Exec[islandora_drupal_install]")
        .that_requires("Postgresql::Server::Db[islandora]")
    end

    it { should create_class('fedora_commons')}
    it { should create_class('postgresql::globals')}
    it { should create_class('postgresql::server')}
    it { should create_class('apache')}

    it { should have_firewall_resource_count(1) }

  end
end
