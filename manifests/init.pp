# == Class: islandora
#
# This is the class for solr
#
#
# == Parameters
#
# Standard class parameters - Define solr web app specific settings
#
#
#
#
# == Examples
#
# See README
#
#
# == Author
#   James R. Griffin III <griffinj@lafayette.edu/>
#
class islandora (

  $islandora_filter_download_url = params_lookup( 'islandora_filter_download_url' ),
  $islandora_filter_debug = params_lookup( 'islandora_filter_debug' )
  
  ) inherits islandora::params {

    # Install the service
    require islandora::install
  }
