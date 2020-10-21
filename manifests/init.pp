# ds_389
#
# Installs and manages 389 Directory Server
#
# @summary Installs and manages 389 Directory Server
#
# @example
#   include ds_389
#
# @param cacerts_path Target directory the 389 ds certs should be exported to. Default: '/etc/openldap/cacerts'
# @param dnf_module_name The name of the DNF module that should be enabled on RHEL. Optional.
# @param dnf_module_version The version of the DNF module that should be enabled on RHEL. Optional.
# @param group Group account 389 ds user should belong to. Default: 'dirsrv'
# @param home_dir Home directory for the 389 ds user account. Default: '/usr/share/dirsrv'
# @param instances A hash of ds_389::instance resources. Optional.
# @param package_ensure 389 ds package state. Default 'installed'
# @param package_name Name of the 389 ds package to install. Default: '389-ds-base'
# @param service_type The service manager that should be used.
# @param user User account 389 ds should run as. Default: 'dirsrv'
#
class ds_389 (
  Stdlib::Absolutepath $cacerts_path,
  String $cacert_rehash,
  String $group,
  Stdlib::Absolutepath $home_dir,
  Hash $instances,
  Stdlib::Absolutepath $limits_config_dir,
  String $nsstools_package_name,
  String $package_ensure,
  Variant[String,Array] $package_name,
  String $path,
  String $service_type,
  Stdlib::Absolutepath $ssl_dir,
  Boolean $ssl_version_min_support,
  String $user,
  String $user_shell,
  Optional[String] $dnf_module_name = undef,
  Optional[String] $dnf_module_version = undef,
) {
  class { 'ds_389::install': }

  if $instances {
    $instances.each |$instance_name, $params| {
      ds_389::instance { $instance_name:
        root_dn           => $params['root_dn'],
        suffix            => $params['suffix'],
        cert_db_pass      => $params['cert_db_pass'],
        root_dn_pass      => $params['root_dn_pass'],
        group             => $params['group'],
        user              => $params['user'],
        server_id         => $params['server_id'],
        server_host       => $params['server_host'],
        server_port       => $params['server_port'],
        server_ssl_port   => $params['server_ssl_port'],
        subject_alt_names => $params['subject_alt_names'],
        replication       => $params['replication'],
        ssl               => $params['ssl'],
        ssl_version_min   => $params['ssl_version_min'],
        schema_extensions => $params['schema_extensions'],
        modify_ldifs      => $params['modify_ldifs'],
        add_ldifs         => $params['add_ldifs'],
        base_load_ldifs   => $params['base_load_ldifs'],
        require           => Class['ds_389::install'],
      }
    }
  }
}
