# ds_389::params
#
# This class sets parameters according to platform
#
class ds_389::params {

  case $::osfamily {
    'Debian': {
      $ssl_dir = '/etc/ssl'
      $user_shell = '/bin/false'
      $nsstools_package_name = 'libnss3-tools'
      $setup_ds = 'setup-ds'
      $cacert_rehash = 'c_rehash'
      $limits_config_dir = '/etc/default'
      $package_name = '389-ds-base'
      $dnf_module_name = undef
      $dnf_module_version = undef
      case $::operatingsystemmajrelease {
        '8', '9', '16.04': {
          $service_type = 'systemd'
          $ssl_version_min_support = true
        }
        default: {
          $service_type = 'init'
          $ssl_version_min_support = false
        }
      }
    }
    'RedHat': {
      $ssl_dir = '/etc/pki/tls/certs'
      $user_shell = '/sbin/nologin'
      $nsstools_package_name = 'nss-tools'
      $setup_ds = 'setup-ds.pl'
      $limits_config_dir = '/etc/sysconfig'
      case $::operatingsystemmajrelease {
        '7': {
          $service_type = 'systemd'
          $ssl_version_min_support = true
          $cacert_rehash = 'cacertdir_rehash'
          $package_name = '389-ds-base'
          $dnf_module_name = undef
          $dnf_module_version = undef
        }
        '8': {
          $service_type = 'systemd'
          $ssl_version_min_support = true
          $cacert_rehash = 'openssl rehash'
          $package_name = ['389-ds-base','389-ds-base-legacy-tools']
          $dnf_module_name = '389-ds'
          $dnf_module_version = '1.4'
        }
        default: {
          $service_type = 'init'
          $ssl_version_min_support = false
          $cacert_rehash = 'cacertdir_rehash'
          $package_name = '389-ds-base'
          $dnf_module_name = undef
          $dnf_module_version = undef
        }
      }
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
}
