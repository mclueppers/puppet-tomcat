class tomcat::params (
  $download_url = hiera('tomcat::params::download_url', 'http://archive.apache.org/dist/tomcat'),
  $base_folder  = hiera('tomcat::params::base_folder', '/home/mdobrev'),
  $use_repo     = hiera('tomcat::params::use_repo', false),
  $version      = hiera('tomcat::params::version', '7.0.54'),
  $pkgname      = hiera('tomcat::params::pkgname', undef)
){
  if $version =~ /^(\d+)\.\d+\.\d+.*/ {
    $majorversion = $1
  }

  $cache_dir_r = "/var/cache/tomcat${majorversion}"
  $log_dir_r   = "/var/log/tomcat${majorversion}"
  $app_dir_r   = "${base_folder}/tomcat${majorversion}"
  $initd_r     = "/etc/init.d/tomcat${majorversion}"

  case $::operatingsystem {
    'RedHat', 'CentOS': {
      $sysconfig_r = "/etc/sysconfig/tomcat${majorversion}"

      case $::operatingsystemmajrelease {
        '6': {
          $share_dir_r = "/usr/share/tomcat6"
          $initd_r     = "/etc/init.d/tomcat${majorversion}"

          if $pkgname == undef {
            $pkgname_r = $majorversion ? {
              '6'     => 'tomcat6',
              default => 'tomcat'
            }
          } else {
            $pkgname_r = $pkgname
          }
        }
        '7': {
          $share_dir_r = "/usr/share/tomcat"
          $initd_r     = '/usr/lib/systemd/system/tomcat.service'

          if $pkgname == undef {
            $pkgname_r = 'tomcat'
          } else {
            $pkgname_r = $pkgname
          }
        }
      }
    }

    'Debian', 'Ubuntu': {
      $share_dir_r = "/usr/share/tomcat"
      $sysconfig_r = "/etc/default/tomcat${majorversion}"

      if $pkgname == undef {
        $pkgname_r = $majorversion ? {
          '6'     => 'tomcat6',
          default => 'tomcat7'
        }
      } else {
        $pkgname_r = $pkgname
      }
    }
  }
}