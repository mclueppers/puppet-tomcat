# Installs Tomcat either from binary archive or from repository

class tomcat::install { # lint:ignore:autoloader_layout
  if ! $::tomcat::use_repo {
    exec { "download-tomcat-${::tomcat::version} to ${::tomcat::base_folder}":
      cwd     => "${::tomcat::base_folder}", # lint:ignore:only_variable_string
      path    => '/bin:/sbin:/usr/sbin:/usr/bin',
      creates => "${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz", # lint:ignore:80chars
      command => "wget ${::tomcat::download_url}/tomcat-${::tomcat::params::majorversion}/v${::tomcat::version}/bin/apache-tomcat-${::tomcat::version}.tar.gz -O ${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz", # lint:ignore:80chars
      notify  => Exec["extract-tomcat-${::tomcat::version} to ${::tomcat::base_folder}"] # lint:ignore:80chars
    }

    exec { "extract-tomcat-${::tomcat::version} to ${::tomcat::base_folder}":
      cwd     => "${::tomcat::base_folder}", # lint:ignore:only_variable_string
      path    => '/bin:/sbin:/usr/sbin:/usr/bin',
      creates => "${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}",
      command => "tar -zxf ${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz -C ${::tomcat::base_folder}", # lint:ignore:80chars
      require => Exec["download-tomcat-${::tomcat::version} to ${::tomcat::base_folder}"] # lint:ignore:80chars
    }
  } else {
    package { "tomcat${::tomcat::params::majorversion}":
      ensure => latest,
      name   => "${::tomcat::params::pkgname_r}" # lint:ignore:80chars lint:ignore:only_variable_string
    }
  }
}