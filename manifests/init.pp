# Class: wso2bam
#
# This module manages wso2bam
#
# Parameters:
#    [*db_type*]  - The type of the DB where to store the AM data (as for now just MySQL is supported
#    [*db_host*]  - The host of the MySQL DB
#    [*db_name*]  - The name of the schema for AM (it will be created)
#    [*db_user*]  - The user of the DB
#    [*db_password*]  - The password
#    [*db_tag*]  - The tag used to create the external resource to allow the remote MySQL puppet controlled machine to create the DB
#    [*product_name*]  - This is here for possible evolution of the module, do not use right now
#    [*version*]  - Version of the product to install only 2.0.1 and 2.2.0 are supported
#    [*download_site*]  - The download site where to get the ZIP (you are advised to provide your HTTP site)
#    [*admin_password*]  - The admin password for the API manager
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class wso2bam (
  $db_type         = $wso2bam::params::db_type,
  $db_host         = $wso2bam::params::db_host,
  $db_name         = $wso2bam::params::db_name,
  $db_user         = $wso2bam::params::db_user,
  $db_password     = $wso2bam::params::db_password,
  $db_tag          = $wso2bam::params::db_tag,
  $product_name    = $wso2bam::params::product_name,
  $download_site   = $wso2bam::params::download_site,
  $admin_password  = $wso2bam::params::admin_password,
  $external_greg   = $wso2bam::params::external_greg,
  $greg_server_url = $wso2bam::params::greg_server_url,
  $greg_db_host    = $wso2bam::params::greg_db_host,
  $greg_db_name    = $wso2bam::params::greg_db_name,
  $greg_db_type    = $wso2bam::params::greg_db_type,
  $greg_username   = $wso2bam::params::greg_username,
  $greg_password   = $wso2bam::params::greg_password,
  $thrifthost      = $wso2bam::params::thrifthost,
  $used_by_api = $wso2bam::params::used_by_api,
  $db_api_name         = $wso2bam::params::db_api_name,
  $version         = '2.2.0',) inherits wso2bam::params {
  if !($version in ['2.0.1', '2.2.0', '2.3.0', '2.4.0']) {
    fail("\"${version}\" is not a supported version value")
  }
  $archive = "$product_name-$version.zip"
  $dir_bin = "/opt/wso2bam-${version}/bin/"

  exec { "get-bam-$version":
    cwd     => '/opt',
    command => "/usr/bin/wget ${download_site}${archive}",
    creates => "/opt/${archive}",
  }

  exec { "unpack-bam-$version":
    cwd       => '/opt',
    command   => "/usr/bin/unzip ${archive}",
    creates   => "/opt/wso2bam-$version",
    subscribe => Exec["get-bam-$version"],
    require   => Package['unzip'],
  }

  case $db_type {
    undef   : {
      # Use default H2 database
    }
    h2      : {
      # Use default H2 database
    }
    mysql   : {
      # we'll need a DB and a user for the local and config stuff
      @@mysql::db { $db_name:
        user     => $db_user,
        password => $db_password,
        host     => $::fqdn,
        grant    => ['all'],
        tag      => $db_tag,
      }

      file { "/opt/${product_name}-$version/repository/components/lib/mysql-connector-java-5.1.22-bin.jar":
        source  => "puppet:///modules/wso2bam/mysql-connector-java-5.1.22-bin.jar",
        owner   => 'root',
        group   => 'root',
        mode    => 0644,
        require => Exec["unpack-bam-$version"],
        before  => File["/opt/${product_name}-$version/bin/wso2server.sh"],
      }

      file { "/opt/${product_name}-$version/repository/conf/datasources/master-datasources.xml":
        content => template("wso2bam/${version}/master-datasources.xml.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => 0644,
        require => Exec["unpack-bam-$version"],
        before  => File["/opt/${product_name}-$version/bin/wso2server.sh"],
      }

      if $external_greg == "true" {
        @@database_user { "${greg_username}@${fqdn}":
          ensure        => 'present',
          password_hash => mysql_password($greg_password),
          tag           => $db_tag,
        }

        @@database_grant { "${greg_username}@${fqdn}/${greg_db_name}":
          privileges => "all",
          tag        => $db_tag,
        }
        notice("asking grant")

      }
    }
    default : {
      fail('currently only mysql is supported - please raise a bug on github')
    }
  }

  file { "/opt/${product_name}-$version/repository/conf/registry.xml":
    content => template("wso2bam/${version}/registry.xml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Exec["unpack-bam-$version"],
  }

  file { "/opt/${product_name}-$version/repository/conf/user-mgt.xml":
    content => template("wso2bam/${version}/user-mgt.xml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Exec["unpack-bam-$version"],
  }

  if ($version in ['2.0.1', '2.2.0', '2.3.0']) {
    file { "/opt/${product_name}-$version/repository/conf/advanced/hive-rss-config.xml":
      content => template("wso2bam/${version}/hive-rss-config.xml.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  } else {
    file { "/opt/${product_name}-$version/repository/conf/advanced/hive-site.xml":
      content => template("wso2bam/${version}/hive-site.xml.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  }

  file { "/opt/${product_name}-$version/repository/conf/axis2/axis2.xml":
    content => template("wso2bam/${version}/axis2.xml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Exec["unpack-bam-$version"],
  }

  file { "/opt/${product_name}-$version/repository/conf/etc/cassandra-auth.xml":
    content => template("wso2bam/${version}/cassandra-auth.xml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Exec["unpack-bam-$version"],
  }

  file { "/opt/${product_name}-$version/repository/conf/etc/tasks-config.xml":
    content => template("wso2bam/${version}/tasks-config.xml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => Exec["unpack-bam-$version"],
  }

  if ($version in ['2.0.1', '2.2.0', '2.3.0']) {
    file { "/opt/${product_name}-$version/repository/conf/security/jaas.conf":
      content => template("wso2bam/${version}/jaas.conf.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  }
  
  if ($version in ['2.4.0']) {
    file { "/opt/${product_name}-$version/repository/conf/data-bridge/data-bridge-config.xml":
      content => template("wso2bam/${version}/data-bridge-config.xml.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  }

  if ($version in ['2.4.0']) {
    file { "/opt/${product_name}-$version/repository/conf/log4j.properties":
      content => template("wso2bam/${version}/log4j.properties.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  }

  if ($version in ['2.4.0']) {
    file { "/opt/${product_name}-$version/repository/conf/security/cipher-text.properties":
      content => template("wso2bam/${version}/cipher-text.properties.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => 0644,
      require => Exec["unpack-bam-$version"],
    }
  }

  file { "/opt/${product_name}-$version/bin/wso2server.sh":
    content => template("wso2bam/${version}/wso2server.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0744,
    require => Exec["unpack-bam-$version"],
  }

  exec { 'setup-${product_name}':
    cwd         => "/opt/${product_name}-${version}/bin/",
    path        => "/opt/${product_name}-${version}/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
    environment => ["JAVA_HOME=/usr/java/default",],
    command     => "wso2server.sh -Dsetup",
    creates     => "/opt/${product_name}-$version/repository/logs/wso2carbon.log",
    unless      => "/usr/bin/test -s /opt/${product_name}-$version/repository/logs/wso2carbon.log",
    logoutput   => true,
    onlyif      => [
      "/usr/bin/mysql -h ${db_host} -u ${db_user} -p${db_password} -e\"show databases\"|grep -q ${db_name}",
      "/usr/bin/mysql -h ${greg_db_host} -u ${greg_username} -p${greg_password} -e\"show databases\"|grep -q ${greg_db_name}"],
    require     => [
      File["/opt/${product_name}-$version/repository/conf/user-mgt.xml"],
      File["/opt/${product_name}-$version/repository/conf/registry.xml"],
      File["/opt/${product_name}-$version/bin/wso2server.sh"],
      File["/opt/${product_name}-$version/repository/conf/datasources/master-datasources.xml"],
      File["/opt/${product_name}-$version/repository/conf/axis2/axis2.xml"]],
  }
  notice("/usr/bin/mysql -h ${greg_db_host} -u ${greg_username} -p${greg_password} -e\"show databases\"|grep -q ${greg_db_name}")

  file { "/etc/init.d/${product_name}":
    ensure => link,
    owner  => 'root',
    group  => 'root',
    target => "/opt/${product_name}-$version/bin/wso2server.sh",
  }
}
