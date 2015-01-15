# == Class: islandora
#
# Parameters for the islandora Class
#
class islandora::params {

  $version = '7.x-1.4'
  $doc_root = "/var/www/islandora-${version}"
  $islandora_filter_download_url = 'https://github.com/Islandora/islandora_drupal_filter/releases/download/v7.1.3/fcrepo-drupalauthfilter-3.7.0.jar'

  # $FEDORA_HOME/tomcat/webapps/fedora/WEB-INF/lib

  # Apache Tomcat
  $servlet_engine = 'tomcat'
  $servlet_webapps_dir_path = '/var/lib/tomcat/webapps'
  $servlet_context_dir_path = '/etc/tomcat/Catalina/localhost'
  $servlet_host = 'localhost'
  $servlet_port = 8080

  # Apache Solr
  $solr_host = 'localhost'
  $solr_context = 'solr'
  $solr_index_name = 'fedora'

  ## Database Management System
  $database_type = 'postgresql'
  $database_user = 'islandora'
  $database_pass = 'secret'
  $database_server = 'localhost'
  $database_port = 5432
  $database_name = 'islandora'
}