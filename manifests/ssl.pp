# @summary Manages SSL for a 389 ds instance.
#
# @example
#   ds_389::ssl { 'foo':
#     cert_name    => 'fooCert'
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @param cert_name
#   The nickname of the SSL cert to use. Required.
#
# @param group
#   The group of the created ldif file. Default: $ds_389::group
#
# @param minssf
#   The minimum security strength for connections. Default: 0
#
# @param root_dn_pass
#   The password to use when calling ldapmodify. Required.
#
# @param root_dn
#   The bind DN to use when calling ldapmodify. Required.
#
# @param server_host
#   The host to use when calling ldapmodify. Default: `$facts['networking']['fqdn']`
#
# @param server_port
#   The port to use when calling ldapmodify. Default: 389
#
# @param server_ssl_port
#   The port to use for SSL traffic. Default: 636
#
# @param ssl_version_min
#   The minimum TLS version to allow. Default: 'TLS1.1'
#
# @param user
#   The owner of the created ldif file. Default: $ds_389::user
#
define ds_389::ssl (
  String $cert_name,
  String $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  String $group = $ds_389::group,
  Integer $minssf = 0,
  String $server_host = $facts['networking']['fqdn'],
  Integer $server_port = 389,
  Integer $server_ssl_port = 636,
  String $ssl_version_min = 'TLS1.1',
  String $user = $ds_389::user,
) {
  include ds_389

  if $ds_389::service_type == 'systemd' {
    $service_restart_command = "systemctl restart dirsrv@${name}"
  }
  else {
    $service_restart_command = "service dirsrv restart ${name}"
  }

  $security_enable_done = "/etc/dirsrv/slapd-${name}/ssl_enable.done"
  $security_enable_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "ldap://${server_host}:${server_port}",
      'config replace',
      "nsslapd-securePort=${server_ssl_port}",
      'nsslapd-security=on',
      "nsslapd-minssf=${minssf}",
      'nsslapd-SSLclientAuth=off',
      "&& touch ${security_enable_done}",
  ], ' ')

  $security_config_done = "/etc/dirsrv/slapd-${name}/ssl_config.done"
  $security_config_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "ldap://${server_host}:${server_port}",
      'security rsa set',
      '--tls-allow-rsa-certificates on',
      '--nss-token "internal (software)"',
      "--nss-cert-name ${cert_name}",
#     "--tls-protocol-min ${ssl_version_min}",
      "&& touch ${security_config_done}",
  ], ' ')

  # NOTE: This ensures that the status is not lost when migrating from
  # spacepants/puppet-ds_389 to this module. This migration path will
  # be removed in a later version.
  exec { "Migrate SSL status: ${name}":
    command => "touch ${security_enable_done} && touch ${security_config_done}",
    path    => $ds_389::path,
    creates => $security_enable_done,
    onlyif  => "test -f /etc/dirsrv/slapd-${name}/ssl.done",
    before  => [
      Exec["Enable security: ${name}"],
      Exec["Configure security parameters: ${name}"],
    ],
  }

  # XXX: Neither sslVersionMin nor --tls-protocol-min work with dsconf, so
  # we still have to use ldif to configure some parameters.
  file { "/etc/dirsrv/slapd-${name}/ssl.ldif":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => epp('ds_389/ssl.epp',{
        ssl_version_min => $ssl_version_min,
    }),
  }
  -> exec { "Import ssl ldif: ${name}":
    command => "ldapmodify -xH ldap://${server_host}:${server_port} -D \"${root_dn}\" -w ${root_dn_pass} -f /etc/dirsrv/slapd-${name}/ssl.ldif && touch /etc/dirsrv/slapd-${name}/ssl.done", # lint:ignore:140chars
    path    => $ds_389::path,
    creates => "/etc/dirsrv/slapd-${name}/ssl.done",
    require => File["/etc/dirsrv/slapd-${name}/ssl.ldif"],
    notify  => Exec["Restart ${name} to enable SSL"],
  }
  -> exec { "Enable security: ${name}":
    command => $security_enable_command,
    path    => $ds_389::path,
    creates => $security_enable_done,
    notify  => Exec["Restart ${name} to enable SSL"],
  }
  -> exec { "Configure security parameters: ${name}":
    command => $security_config_command,
    path    => $ds_389::path,
    creates => $security_config_done,
    notify  => Exec["Restart ${name} to enable SSL"],
  }

  exec { "Restart ${name} to enable SSL":
    command     => "${service_restart_command} ; sleep 2",
    path        => $ds_389::path,
    refreshonly => true,
  }
}
