# Installs Tomcat either from binary archive or from repository

class tomcat::install { # lint:ignore:autoloader_layout
  # Make sure base_folder exists

  file { "${::tomcat::base_folder}":
    ensure => directory
  }

  if ! $::tomcat::use_repo {
    $ajp_port      = 38080
    $account       = "root"
    $instance_name = "apache-tomcat-${::tomcat::version}"

    $initd_final   = $::tomcat::params::initd_type ? {
      'sysv'    => "${::tomcat::params::initd_r}-${name}",
      'systemd' => "/usr/lib/systemd/system/tomcat@${name}.service",
      'default' => "${::tomcat::params::initd_r}-${name}"
    }

    exec { "download-tomcat-${::tomcat::version} to ${::tomcat::base_folder}":
      cwd     => "${::tomcat::base_folder}", # lint:ignore:only_variable_string
      path    => '/bin:/sbin:/usr/sbin:/usr/bin',
      creates => "${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz", # lint:ignore:80chars
      command => "wget ${::tomcat::download_url}/tomcat-${::tomcat::params::majorversion}/v${::tomcat::version}/bin/apache-tomcat-${::tomcat::version}.tar.gz -O ${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz", # lint:ignore:80chars
      notify  => Exec["extract-tomcat-${::tomcat::version} to ${::tomcat::base_folder}"], # lint:ignore:80chars
      require => File["${::tomcat::base_folder}"]
    }

    exec { "extract-tomcat-${::tomcat::version} to ${::tomcat::base_folder}":
      cwd     => "${::tomcat::base_folder}", # lint:ignore:only_variable_string
      path    => '/bin:/sbin:/usr/sbin:/usr/bin',
      creates => "${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}",
      command => "tar -zxf ${::tomcat::base_folder}/apache-tomcat-${::tomcat::version}.tar.gz -C ${::tomcat::base_folder}", # lint:ignore:80chars
      require => Exec["download-tomcat-${::tomcat::version} to ${::tomcat::base_folder}"] # lint:ignore:80chars
    }

    file { "${::tomcat::params::sysconfig_r}":
      content => template("tomcat/sysconfig.erb"),
      require => Exec["extract-tomcat-${::tomcat::version} to ${::tomcat::base_folder}"]
    }

    file { "${::tomcat::params::initd_r}":
      content => template("tomcat/${::tomcat::params::initd_template}"),
      mode    => "0755",
      require => File["${::tomcat::params::sysconfig_r}"]
    }

    if $::tomcat::params::initd_type == "systemd" {
      file { "${::tomcat::base_folder}/libexec":
        replace => false,
        recurse => true,
        purge   => false,
        source  => "puppet:///modules/tomcat/systemd-libexec/",
        owner   => 'root',
        group   => 'root',
      }
    }
  } else {
    package { "tomcat${::tomcat::params::majorversion}":
      ensure  => latest,
      name    => "${::tomcat::params::pkgname_r}", # lint:ignore:80chars lint:ignore:only_variable_string
      require => File["${::tomcat::base_folder}"]
    }
  }
}
