# ds_389::install
#
# This class is called from ds_389 for installation.
#
class ds_389::install {
  file { '/etc/dirsrv':
    ensure => directory,
  }
  exec { 'Create ldap cacerts directory':
    command => "/bin/mkdir -p ${::ds_389::cacerts_path}",
    creates => $::ds_389::cacerts_path,
  }

  # Enable required dnf module on RHEL/CentOS 8.
  if (($::osfamily == 'RedHat') and ($::operatingsystemmajrelease == '8')) {
    package { $::ds_389::dnf_module_name:
      ensure      => $::ds_389::dnf_module_version,
      enable_only => true,
      provider    => 'dnfmodule',
    }
  }

  # Support multiple package names by converting everything to an Array.
  $_packages = Array($::ds_389::package_name, true)
  ensure_packages($_packages,
  {
    ensure  => $::ds_389::package_ensure,
    require => [
      File['/etc/dirsrv'],
      Exec['Create ldap cacerts directory'],
    ],
  })

  package { $::ds_389::nsstools_package_name:
    ensure => 'installed',
  }

  group { $::ds_389::group:
    ensure => present,
    system => true,
  }
  user { $::ds_389::user:
    ensure  => present,
    system  => true,
    home    => $::ds_389::home_dir,
    shell   => $::ds_389::user_shell,
    gid     => $::ds_389::group,
    require => Group[$::ds_389::group],
  }
  if $::ds_389::service_type == 'systemd' {
    ini_setting { 'dirsrv ulimit':
      ensure  => present,
      path    => "${::ds_389::limits_config_dir}/dirsrv.systemd",
      section => 'Service',
      setting => 'LimitNOFILE',
      value   => '8192',
      require => Package[$::ds_389::package_name],
    }
  }
  else {
    file_line { 'dirsrv ulimit':
      ensure  => present,
      path    => "${::ds_389::limits_config_dir}/dirsrv",
      line    => 'ulimit -n 8192',
      require => Package[$::ds_389::package_name],
    }
  }
}
