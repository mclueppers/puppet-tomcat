# Installs and configures a Tomcat instance

define tomcat::instance (
  $account = undef,
  $ajp_port = undef,
  $http_port = undef,
  $shutdown_port = undef,
  $home_group = undef,
  $log_group = undef,
  $resources = undef,
  $tomcat_cluster = false,
  $catalina_opts = undef,
  $templates_url = undef,
  $tomcat_admin_user = undef,
  $tomcat_admin_password = undef
) {
  if ! defined(Class['tomcat']) {
    include tomcat
  }

  $instance_name = "tomcat${::tomcat::params::majorversion}/$name"
  $catalina_home = "${::tomcat::params::share_dir_r}"

  $initd_final   = $::tomcat::params::initd_type ? {
    'sysv'    => "${::tomcat::params::initd_r}-${name}",
    'systemd' => "/usr/lib/systemd/system/tomcat${::tomcat::params::majorversion}-${name}.service",
    'default' => "${::tomcat::params::initd_r}-${name}"
  }

  $home_group_r = $home_group ? {
    undef   => $account,
    default => $home_group,
  }

  $log_group_r = $log_group ? {
    undef   => $account,
    default => $log_group,
  }

  file { "${::tomcat::params::sysconfig_r}-${name}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('tomcat/sysconfig.erb')
  }

  file { $initd_final:
    ensure  => link,
    owner   => 'root',
    group   => 'root',
    target  => "${::tomcat::params::initd_r}",
    require => Class['tomcat::install'],
  }

  ######
  # Cache Directories
  ######
  $cache_dirs = [ "${::tomcat::params::cache_dir_r}",
                  "${::tomcat::params::cache_dir_r}/${name}",
                  "${::tomcat::params::cache_dir_r}/${name}/temp",
                  "${::tomcat::params::cache_dir_r}/${name}/work" ]
  file { $cache_dirs:
    ensure => directory,
    owner  => $account,
    group  => $account,
    mode   => '2775',
  }

  #######
  # Application Home Resources
  #######
  $app_dirs = [ "${::tomcat::params::app_dir_r}",
                "${::tomcat::params::app_dir_r}/${name}",
                "${::tomcat::params::app_dir_r}/${name}/Catalina",
                "${::tomcat::params::app_dir_r}/${name}/Catalina/localhost",
                "${::tomcat::params::app_dir_r}/${name}/Catalina/lib",
                "${::tomcat::params::app_dir_r}/${name}/webapps" ]

  file { $app_dirs:
    ensure  => directory,
    replace => false,
    owner   => $account,
    group   => $home_group_r,
    mode    => '2775',
  }

  file { "${::tomcat::params::app_dir_r}/${name}/temp":
    ensure => link,
    owner  => $account,
    group  => $log_group_r,
    mode   => '2775',
    target => "${::tomcat::params::cache_dir_r}/${name}/temp"
  }

  file { "${::tomcat::params::app_dir_r}/${name}/work":
    ensure => link,
    owner  => $account,
    group  => $log_group_r,
    mode   => '2775',
    target => "${::tomcat::params::cache_dir_r}/${name}/work"
  }

  file { [ "${::tomcat::params::log_dir_r}", "${::tomcat::params::log_dir_r}/${name}" ]:
    ensure => directory,
    owner  => $account,
    group  => $log_group_r,
    mode   => '2775',
  }

  file { "${::tomcat::params::app_dir_r}/${name}/logs":
    ensure => link,
    owner  => $account,
    group  => $log_group_r,
    mode   => '2775',
    target => "${::tomcat::params::log_dir_r}/${name}",
  }

  file { "${::tomcat::params::app_dir_r}/${name}/bin":
    ensure => link,
    owner  => $account,
    group  => $home_group_r,
    mode   => '2775',
    target => "${::tomcat::params::share_dir_r}/bin",
  }

  #######
  # Initial Configuration Files
  #######

  #######
  # Cluster configuration
  #######
  if is_hash($tomcat_cluster) {
    if is_hash($tomcat_cluster['deployer']) {
      $deployer = $tomcat_cluster['deployer']
    }

    if is_hash($tomcat_cluster['receiver']) {
      $receiver = $tomcat_cluster['receiver']
    }

    if is_hash($tomcat_cluster['membership']) {
      $membership = $tomcat_cluster['membership']
    }
    
    $jvmroute = $::hostname
  }

  $defaulthost = 'localhost'

  $tomcat_engine = template('tomcat/server-xml-engine.erb')

  file { "${::tomcat::params::app_dir_r}/${name}/conf":
    replace => false,
    recurse => true,
    purge   => false,
    source  => "file:${::tomcat::params::share_dir_r}/conf",
    owner   => $account,
    group   => $home_group_r,
    mode    => '0664',
  } ->

  file { [ "${::tomcat::params::app_dir_r}/${name}/conf/Catalina", 
           "${::tomcat::params::app_dir_r}/${name}/conf/Catalina/localhost"]:
    ensure => directory,
    owner  => $account,
    group  => $home_group_r,
    mode   => '0664',
  } ->

  file { "tomcat-users.xml-${name}":
    ensure  => file,
    path    => "${::tomcat::params::app_dir_r}/${name}/conf/tomcat-users.xml",
    owner   => $account,
    group   => $home_group_r,
    mode    => '0664',
    content => template('tomcat/tomcat-users.xml.erb'),
    notify  => Service["tomcat${::tomcat::params::majorversion}-${name}"]
  } ->

  file { "manager.xml-${name}":
    ensure  => file,
    path    => "${::tomcat::params::app_dir_r}/${name}/conf/Catalina/localhost/manager.xml",
    owner   => $account,
    group   => $home_group_r,
    mode    => '0664',
    content => template('tomcat/manager.xml.erb'),
    notify  => Service["tomcat${::tomcat::params::majorversion}-${name}"]
  }

  concat { "${::tomcat::params::app_dir_r}/${name}/conf/server.xml":
    owner => $account,
    group => $home_group_r,
    mode  => '0664',
  }

  concat::fragment { "server.xml.header-${name}":
    content => template('tomcat/server-xml-header.erb'),
    target  => "${::tomcat::params::app_dir_r}/${name}/conf/server.xml",
    order   => 01,
  }

  concat::fragment { "server.xml.footer-${name}":
    content => template('tomcat/server-xml-footer.erb'),
    target  => "${::tomcat::params::app_dir_r}/${name}/conf/server.xml",
    order   => 99,
  }

  #######
  # Service Configuration
  #######
  service { "tomcat${::tomcat::params::majorversion}-${name}":
    enable  => true,
    require => File["${::tomcat::params::initd_r}-${name}"],
  }
}
