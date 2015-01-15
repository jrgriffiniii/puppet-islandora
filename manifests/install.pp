# == Class: islandora::install
#
# Class for managing the installation process of Fedora Generic Search
#
class islandora::install inherits islandora {

  exec { 'islandora_download':
    
    command => "/usr/bin/env wget ${islandora::download_url} -O /tmp/islandora.zip",
    unless => '/usr/bin/env stat /tmp/islandora.zip'
  }

  exec { 'islandora_deploy':

    command => "/usr/bin/env unzip /tmp/islandora.zip islandora.war -d ${islandora::servlet_webapps_dir_path}",
    require => Exec['islandora_download']
  }

  exec { 'islandora_filter_download':
    
    command => "/usr/bin/env wget ${islandora_filter_download_url} -O /tmp/fcrepo-drupalauthfilter-3.7.0.jar",
    unless => '/usr/bin/env stat /tmp/fcrepo-drupalauthfilter-3.7.0.jar'
  }

  exec { 'islandora_filter_deploy':

    command => "/usr/bin/env cp /tmp/fcrepo-drupalauthfilter-3.7.0.jar ${servlet_webapps_dir_path}/fedora/WEB-INF/lib",
    unless => "/usr/bin/env stat ${servlet_webapps_dir_path}/fedora/WEB-INF/lib/fcrepo-drupalauthfilter-3.7.0.jar",
    require => Exec['filter_download']
  }

  file_line { 'islandora_fedora_config_filter':

    path => "${islandora::fedora_home}/server/config/jaas.conf",
    line => template('islandora/jaas.conf.erb'),
    after => "org.fcrepo.server.security.jaas.auth.module.XmlUsersFileModule required\ndebug=true;"
  }
  
  file_line { 'islandora_fedora_add_filter':

    path => "${islandora::fedora_home}/server/config/fedora-users.xml",
    line => template('islandora/fedora-users.xml.erb')
  }

  # PostgreSQL
  # @todo Refactor with hiera (for default parameter parsing)
  ensure_resource('class', 'postgresql::globals', { manage_package_repo => true })
  ensure_resource('class', 'postgresql::server', {
    
    listen_addresses => '*',

    # ip_mask_deny_postgres_user => '0.0.0.0/32',
    # ip_mask_allow_all_users    => '0.0.0.0/0',
    # ipv4acls                   => ['hostssl all 192.168.0.0/24 cert'],
    postgres_password          => 'secret',
    require => Class['postgresql::globals']
    })

  # Create the database for the repository
  # Use either MySQL or PostgreSQL
  postgresql::server::role { $islandora::database_user:
    
    password_hash => postgresql_password($islandora::database_user, $islandora::database_pass),
    require => Class['postgresql::server']
  }
    
  postgresql::server::db { $islandora::database:
    
    user     => $islandora::database_user,
    password => postgresql_password($islandora::database_user, $islandora::database_pass),
    require => Postgresql::Server::Role[$islandora::database_user]
  }

  # Drush
  include '::drush'

  exec { 'islandora_drush_env' :
    
    command => "/bin/bash -c \"export PGPASS=${pg_pass}\"",
    require => Class['::drush']
  }

  file { '/tmp/islandora.makefile':

    content => template('islandora/islandora.makefile.erb')
  }

  drush::exec { "islandora_drupal_install":

    command => "make",
    options => [ '/tmp/islandora.makefile', $islandora::doc_root ]
    require => [ Exec['islandora_drush_env'], File['/tmp/islandora.makefile'] ]
  }
  
  drush::exec { "islandora_deploy":

    command => "si --account-mail=admin@islandora.localdomain --account-pass=secret --db-url=pgsql://islandora:secret@localhost:5432/islandora --site-mail=admin@islandora.localdomain --site-name=Islandora",
    root_directory => '/var/www/islandora-7.x-1.4',
    options => [ '--yes' ],
    require => Exec['islandora_drupal_install']
  }
}
