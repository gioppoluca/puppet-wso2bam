define wso2bam::add_analitics($tbox_path){
  file { "/opt/${wso2bam::product_name}-${wso2bam::version}/repository/deployment/server/bam-toolbox/${name}":
    source  => "puppet:///modules/wso2bam/${tbox_path}/${name}",
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
  }

}