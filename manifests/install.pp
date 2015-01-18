# == Class: islandora::install
#
# Class for managing the installation process of Fedora Generic Search
#
class islandora::install inherits islandora {

  exec { 'islandora_filter_download':
    
    command => "/usr/bin/env wget ${islandora::islandora_filter_download_url} -O /tmp/fcrepo-drupalauthfilter-3.7.0.jar",
    unless => '/usr/bin/env stat /tmp/fcrepo-drupalauthfilter-3.7.0.jar'
  }

  exec { 'islandora_filter_deploy':

    command => "/usr/bin/env cp /tmp/fcrepo-drupalauthfilter-3.7.0.jar ${islandora::servlet_webapps_dir_path}/fedora/WEB-INF/lib",
    unless => "/usr/bin/env stat ${islandora::servlet_webapps_dir_path}/fedora/WEB-INF/lib/fcrepo-drupalauthfilter-3.7.0.jar",
    require => Exec['islandora_filter_download']
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

  # @todo Refactor with hiera (for default parameter parsing)
  
  # Loading the RDBMS
  if $islandora::database == '' or !defined( $islandora::database ) {

    # Select the package to install
    case $islandora::database_type {

      'postgresql':  {
        
        if !defined( Class['postgresql::globals'] ) {        # Ensure that the proper release has been installed
          
          class { 'postgresql::globals':

            manage_package_repo => true,
            version             => '9.2'
          }
        }
      }

      default: {} # @todo Implement for MySQL
    }
  }

  # Starting the RDBMS server
  if $islandora::database_server == '' or !defined( $islandora::database_server ) {

    case $islandora::database_type {

      'postgresql':  {

        if !defined( Class['postgresql::server'] ) { # Ensure that the Class hasn't already been loaded
          
          class { 'postgresql::server':
    
            listen_addresses => '*',

            # ip_mask_deny_postgres_user => '0.0.0.0/32',
            # ip_mask_allow_all_users    => '0.0.0.0/0',
            # ipv4acls                   => ['hostssl all 192.168.0.0/24 cert'],
            postgres_password          => 'secret',
            require => Class['postgresql::globals']
          }
        }
      }
      
      default: {} # @todo Implement for MySQL
    }
  }

  # Drupal site role and database
  # @todo Abstract (for providing a PostGIS database)
  case $islandora::database_type {
    
    'postgis': {} # @todo Implement for PostGIS

    'postgresql':  {
      
      # Create the database for the root site
      postgresql::server::role { $islandora::database_user:
        
        password_hash => postgresql_password($islandora::database_user, $islandora::database_pass),
        require => Class['postgresql::server']
      }
      
      postgresql::server::db { $islandora::database_name:
        
        user     => $islandora::database_user,
        password => postgresql_password($islandora::database_user, $islandora::database_pass),
        require => Postgresql::Server::Role[$islandora::database_user]
      }
    }
    
    default: {} # @todo Implement for MySQL
  }
  
  # Drush
  include '::drush'
  
  exec { 'islandora_drush_env' :
    
    command => "/bin/bash -c \"export PGPASS=${islandora::database_pass}\"",
    require => Class['::drush']
  }
  
  file { '/tmp/islandora.make':
    
    content => template('islandora/islandora.make.erb')
  }
  
  ensure_packages(['git', 'php-mbstring', 'php-gd', 'php-xml', 'php-pgsql', 'php-pdo'])
  
  # Work-around
  # Ensures that the directory doesn't already exist (Drush raises an error)
  file { $islandora::doc_root:
    
    ensure => 'absent',
    force => true
  }
  
  drush::exec { "islandora_drupal_install":
    
    command => "make",
    options => [ '/tmp/islandora.make', $islandora::doc_root ],
    require => [ File[$islandora::doc_root], Exec['islandora_drush_env'], File['/tmp/islandora.make'] ]
  }
  
  drush::exec { "islandora_deploy":
    
    command => "si --account-mail=admin@islandora.localdomain --account-pass=secret --db-url=pgsql://${islandora::database_user}:${islandora::database_pass}@${islandora::database_server}:${islandora::database_port}/${islandora::database_name} --site-mail=admin@islandora.localdomain --site-name=Islandora",
    root_directory => '/var/www/islandora-7.x-1.4',
    options => [ '--yes' ],
    require => [ Drush::Exec['islandora_drupal_install'], Postgresql::Server::Db[$islandora::database_name] ]
  }

  # Loading the HTTP Server
  if $islandora::http_service == '' or !defined( $islandora::http_service ) {

    # Select the HTTP server
    case $islandora::http_service_type {

      'nginx': {} # @todo Implement for nginx
      
      default: {

        if !defined( Class['::apache'] ) { # Ensure that the Class hasn't already been loaded
          
          # Configure Apache HTTP Server

          # Set the DocumentRoot directive for the default VirtualHost
          class { '::apache':
    
            docroot => '/var/www/islandora-7.x-1.4',
            require => Drush::Exec['islandora_deploy'],
            mpm_module => 'prefork'
          }

          # Include mod_php
          include 'apache::mod::php'
        }
      }
    }
  }

  # Add an iptables rule to permit traffic over the HTTP and HTTPS
  # ensure_resource('firewall', '001 allow http and https access for Apache HTTP Server', {
  firewall { '001 allow http and https access for the HTTP Server':
    
    port   => [80, 443],
    proto  => 'tcp',
    action => 'accept'
  }
}
