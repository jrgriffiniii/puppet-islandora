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

    it { should create_class('postgresql::server')}

    it { should create_class('apache')}

    it { should have_firewall_resource_count(1) }

  end
end
