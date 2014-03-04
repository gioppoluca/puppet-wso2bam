# === Class: wso2bam::params
#
#  The WSO2BAM configuration settings idiosyncratic to different operating
#  systems.
#
# === Parameters
#
# None
#
# === Examples
#
# None
#
# === Authors
#
# Luca Gioppo <gioppoluca@libero.it>
#
# === Copyright
#
# Copyright 2012 Luca Gioppo
#
class wso2bam::params {
$db_type            = "h2"
  $db_host            = "wso2mysql.$::domain"
  $db_name            = 'BAM_STATS_DB'
  $db_user            = 'odaibam'
  $db_password        = 'odaibam1'
  $db_tag = 'bam_db'
  $download_site      = 'http://dist.wso2.org/products/governance-registry/'
  $product_name       = 'wso2bam'
  $admin_password       = 'admin'
  $external_greg = 'false'
  $greg_server_url = "localhost"
  $greg_db_host = "localhost"
  $greg_db_name = 'WSO2CARBON_DB'
  $greg_db_type = "h2"
  $greg_username = "admin"
  $greg_password = "admin"
  $thrifthost = '0.0.0.0'
  $used_by_api= "false"
  $db_api_name            = 'APIMGTSTATS_DB'
}
