# ds_389::ssl
#
# Manages ssl for and is intended to be called by a 389 ds instance.
#
# @summary Manages ssl for and is intended to be called by a 389 ds instance.
#
# @example
#   ds_389::ssl { 'foo':
#     cert_name    => 'fooCert'
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @param cert_name The nickname of the SSL cert to use. Required.
# @param group The group of the created ldif file. Default: $::ds_389::group
# @param minssf The minimum security strength for connections. Default: 0
# @param root_dn_pass The password to use when calling ldapmodify. Required.
# @param root_dn The bind DN to use when calling ldapmodify. Required.
# @param server_host The host to use when calling ldapmodify. Default: $::fqdn
# @param server_port The port to use when calling ldapmodify. Default: 389
# @param server_ssl_port The port to use for SSL traffic. Default: 636
# @param ssl_version_min The minimum TLS version to allow. Default: 'TLS1.1'
# @param user The owner of the created ldif file. Default: $::ds_389::user
#
define ds_389::ssl (
  String $cert_name,
  String $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  String $group = $ds_389::group,
  Integer $minssf = 0,
  String $server_host = $::fqdn,
  Integer $server_port = 389,
  Integer $server_ssl_port = 636,
  String $ssl_version_min = 'TLS1.1',
  String $user = $ds_389::user,
) {
  include ds_389

  $ssl_version_min_support = $ds_389::ssl_version_min_support
  if $ds_389::service_type == 'systemd' {
    $service_restart_command = "systemctl restart dirsrv@${name}"
  }
  else {
    $service_restart_command = "service dirsrv restart ${name}"
  }

  file { "/etc/dirsrv/slapd-${name}/ssl.ldif":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template('ds_389/ssl.erb'),
  }
  -> exec { "Import ssl ldif: ${name}":
    command => "ldapmodify -xH ldap://${server_host}:${server_port} -D \"${root_dn}\" -w ${root_dn_pass} -f /etc/dirsrv/slapd-${name}/ssl.ldif ; touch /etc/dirsrv/slapd-${name}/ssl.done", # lint:ignore:140chars
    path    => $ds_389::path,
    creates => "/etc/dirsrv/slapd-${name}/ssl.done",
  }
  ~> exec { "Restart ${name} to enable SSL":
    command     => "${service_restart_command} ; sleep 2",
    path        => $ds_389::path,
    refreshonly => true,
  }
}
