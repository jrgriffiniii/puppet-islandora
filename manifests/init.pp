# == Class: islandora
#
# This is the class for Islandora
#
#
# == Parameters
#
# @todo Structure
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
