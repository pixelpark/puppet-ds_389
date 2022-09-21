# @summary Manages a plugin for a 389 ds instance.
#
# @example Enable a plugin with required params.
#   ds_389::plugin { 'memberof':
#     server_id    => 'foo',
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#   }
#
# @example Disable a plugin when using all params.
#   ds_389::plugin { 'memberof':
#     ensure       => 'disabled',
#     server_id    => 'foo',
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#     server_host  => 'foo.example.com',
#     server_port  => 1389,
#   }
#
# @param ensure
#   The desired state of the plugin. Default: 'enabled'
#
# @param options
#   An array containing additional plugin options. See `man 8 dsconf` for a
#   complete list. Note that several options can only be applied once,
#   further attempts will fail. Optional.
#
# @param protocol
#   The protocol to use when calling ldapadd. Default: 'ldap'
#
# @param root_dn_pass
#   The password to use when calling ldapadd. Required.
#
# @param root_dn
#   The bind DN to use when calling ldapadd. Required.
#
# @param server_host
#   The host to use when calling ldapadd. Default: `$facts['networking']['fqdn']`
#
# @param server_id
#   The 389 ds instance name. Required.
#
# @param server_port
#   The port to use when calling ldapadd. Default: 389
#
define ds_389::plugin (
  String $server_id,
  String $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  Enum['enabled','disabled'] $ensure = 'enabled',
  Array $options = [],
  String $server_host = $facts['networking']['fqdn'],
  Integer $server_port = 389,
  Enum['ldap','ldaps'] $protocol = 'ldap',
) {
  include ds_389

  case $ensure {
    'disabled': {
      $plugin_action = 'disable'
      $plugin_clear_state = "/etc/dirsrv/slapd-${server_id}/plugin_${name}_enabled.done"
    }
    default: {
      $plugin_action = 'enable'
      $plugin_clear_state = "/etc/dirsrv/slapd-${server_id}/plugin_${name}_disabled.done"
    }
  }

  $plugin_done = "/etc/dirsrv/slapd-${server_id}/plugin_${name}_${ensure}.done"
  $plugin_command = join([
      # When changing plugin state, ensure that the flag for the opposite state
      # is cleared. Otherwise it would not be possible to change the state again.
      "rm -f ${plugin_clear_state};",
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "${protocol}://${server_host}:${server_port}",
      'plugin',
      $name,
      $plugin_action,
      "&& touch ${plugin_done}",
  ], ' ')

  exec { "Set plugin ${name} state to ${ensure}: ${server_id}":
    command => $plugin_command,
    path    => $ds_389::path,
    creates => $plugin_done,
  }

  if ($options and $ensure == 'enabled') {
    # Store all options in a file. This way a change can be detected and
    # updated options can be applied.
    $plugin_options_file = "/etc/dirsrv/slapd-${server_id}/plugin_${name}_options"
    file { $plugin_options_file:
      ensure  => file,
      owner   => $ds_389::user,
      group   => $ds_389::group,
      mode    => '0440',
      content => inline_epp('<%= $options %>', { options => $options }),
    }

    # Enable every option individually. This way conflicts can be avoided
    # and failures are easier to track down.
    $options.each |$option| {
      # Command to set the specified plugin option.
      $plugin_option_command = join([
          # Rename the options file. This way a failed command is retried
          # and if the error persists the user is encouraged to fix it.
          "mv -f ${plugin_options_file} ${plugin_options_file}.error &&",
          'dsconf',
          "-D \'${root_dn}\'",
          "-w \'${root_dn_pass}\'",
          "${protocol}://${server_host}:${server_port}",
          'plugin',
          $name,
          $option,
          # If the plugin command succeeds, move the options file back.
          "&& mv -f ${plugin_options_file}.error ${plugin_options_file}",
      ], ' ')

      exec { "Set plugin ${name} options (${option}): ${server_id}":
        command     => $plugin_option_command,
        path        => $ds_389::path,
        refreshonly => true,
        subscribe   => File[$plugin_options_file],
        require     => Exec["Set plugin ${name} state to ${ensure}: ${server_id}"],
      }
    }
  }
}
