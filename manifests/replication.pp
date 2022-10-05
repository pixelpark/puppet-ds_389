# @summary Sets up replication for a 389 ds instance.
#
# @example A basic consumer with required params.
#   ds_389::replication { 'consumer1':
#     bind_dn          => 'cn=Replication Manager,cn=config',
#     replication_pass => 'supersecret',
#     root_dn          => 'cn=Directory Manager',
#     root_dn_pass     => 'supersecure',
#     role             => 'consumer',
#     suffix           => 'dc=example,dc=com',
#   }
#
# @example A basic hub with 2 consumers.
#   ds_389::replication { 'hub1':
#     bind_dn          => 'cn=Replication Manager,cn=config',
#     replication_pass => 'supersecret',
#     root_dn          => 'cn=Directory Manager',
#     root_dn_pass     => 'supersecure',
#     role             => 'hub',
#     suffix           => 'dc=example,dc=com',
#     consumers        => [
#       'consumer1',
#       'consumer2',
#     ],
#   }
#
# @example A basic supplier in multi-master mode with 2 other suppliers and initializing replication.
#   ds_389::replication { 'supplier1':
#     bind_dn          => 'cn=Replication Manager,cn=config',
#     replication_pass => 'supersecret',
#     root_dn          => 'cn=Directory Manager',
#     root_dn_pass     => 'supersecure',
#     role             => 'supplier',
#     suffix           => 'dc=example,dc=com',
#     init_suppliers   => true,
#     suppliers        => [
#       'supplier1',
#       'supplier2',
#     ],
#   }
#
# @param bind_dn
#   The bind dn of the replication user. Required.
#
# @param consumers
#   An array of consumer names to ensure. Optional.
#
# @param excluded_attributes
#   An array of attributes to exclude from replication. Optional.
#
# @param group
#   The group of the created ldif file. Default: $ds_389::group
#
# @param hubs
#   An array of hub names to ensure. Optional.
#
# @param id
#   The replica id. Optional unless declaring a supplier.
#
# @param init_consumers
#   Whether to initialize replication for consumers. Default: false
#
# @param init_hubs
#   Whether to initialize replication for hubs. Default: false
#
# @param init_suppliers
#   Whether to initialize replication for suppliers. Default: false
#
# @param protocol
#   The protocol to use when calling ldapmodify. Default: 'ldap'
#
# @param purge_delay
#   Time in seconds state information stored in replica entries is retained. Default: 604800
#
# @param replica_port
#   The port to use for replication. Default: 389
#
# @param replica_transport
#   The transport type to use for replication. Default: 'LDAP'
#
# @param replication_pass
#   The password of the replication user. Required.
#
# @param replication_user
#   The user account to use for replication.
#
# @param role
#   Replication role. Either 'supplier', 'hub', or 'consumer'. Required.
#
# @param root_dn_pass
#   The root dn password for configuring replication. Required.
#
# @param root_dn
#   The root dn for configuring replication. Required.
#
# @param server_host
#   The host to use when calling ldapmodify. Default: $fqdn
#
# @param server_port
#   The port to use when calling ldapmodify. Default: 389
#
# @param starttls
#   Whether to use StartTLS when calling ldapmodify. Default: false
#
# @param suffix
#   The LDAP suffix to use. Required.
#
# @param suppliers
#   An array of supplier names to ensure. Optional.
#
# @param user
#   The owner of the created ldif file. Default: $ds_389::user
#
define ds_389::replication (
  Variant[String,Sensitive[String]] $replication_pass,
  String $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  Enum['supplier','hub','consumer'] $role,
  String $suffix,
  Optional[String] $bind_dn = undef,
  String $group = $ds_389::group,
  Boolean $init_consumers = false,
  Boolean $init_hubs = false,
  Boolean $init_suppliers = false,
  Enum['ldap','ldaps'] $protocol = 'ldap',
  Integer $purge_delay = 604800,
  Integer $replica_port = 389,
  Enum['LDAP','SSL','TLS'] $replica_transport = 'LDAP',
  String $replication_user = 'Replication Manager',
  String $server_host = $facts['networking']['fqdn'],
  Integer $server_port = 389,
  Boolean $starttls = false,
  String $user = $ds_389::user,
  Optional[Array] $consumers = undef,
  Optional[Array] $excluded_attributes = undef,
  Optional[Array] $hubs = undef,
  Optional[Integer] $id = undef,
  Optional[Array] $suppliers = undef,
) {
  # Restarting the service while initializing could break replication.
  Ds_389::Service<| title == $title |> -> Ds_389::Replication<| title == $title |>

  if $bind_dn {
    $_bind_dn = $bind_dn
  }
  else {
    $_bind_dn = "cn=${replication_user},cn=config"
  }

  if $starttls {
    $_opts = 'ZxH'
  }
  else {
    $_opts = 'xH'
  }

  if $excluded_attributes {
    $_attribute_list = join($excluded_attributes, ' ')
    $attribute_list = "--frac-list=\'${_attribute_list}\'"
  } else {
    $attribute_list = undef
  }

  # Command to enable replication for the specified suffix.
  $_repl_enable_done = "/etc/dirsrv/slapd-${name}/%s_%s_enable.done"
  $_repl_enable_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "${protocol}://${server_host}:${server_port}",
      'replication enable',
      "--suffix \'${suffix}\'",
      '--role=%s',
      '--replica-id=%s',
      "--bind-dn=\'${_bind_dn}\'",
      "--bind-passwd=\'${replication_pass}\'",
      '&& touch %s',
  ], ' ')

  # Command to create a replication agreement between these hosts.
  $_repl_agreement_done = "/etc/dirsrv/slapd-${name}/%s_%s_agreement.done"
  $_repl_agreement_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "${protocol}://${server_host}:${server_port}",
      'repl-agmt create',
      $attribute_list,
      "--suffix=\'${suffix}\'",
      "--host=\'%s\'",
      "--port=${replica_port}",
      "--conn-protocol=${replica_transport}",
      "--bind-dn=\'${_bind_dn}\'",
      "--bind-passwd=\'${replication_pass}\'",
      '--bind-method=SIMPLE',
      "\'${name} to %s agreement\'",
      '&& touch %s',
  ], ' ')

  # Command to update parameters of the replication agreement.
  # TODO: Should be refactored to allow parameters to be changed.
  $_repl_update_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "${protocol}://${server_host}:${server_port}",
      'replication set',
      "--suffix=\'${suffix}\'",
      "--repl-purge-delay=\'${purge_delay}\'",
  ], ' ')

  $_repl_init_done = "/etc/dirsrv/slapd-${name}/%s_%s_init.done"
  $_repl_init_command = join([
      'dsconf',
      "-D \'${root_dn}\'",
      "-w \'${root_dn_pass}\'",
      "${protocol}://${server_host}:${server_port}",
      'repl-agmt init',
      "--suffix=\'${suffix}\'",
      "\'${name} to %s agreement\'",
      '&& touch %s',
  ], ' ')

  case $role {
    'consumer': {
      $type = 2
      $flags = 0
      $_id = 65535
    }
    'hub': {
      $type = 2
      $flags = 1
      $_id = 65535

      if $consumers {
        $consumers.each |$replica| {
          if ($replica != $name) and ($replica != $facts['networking']['fqdn']) {
            # Command to enable replication for the specified suffix.
            $repl_enable_done = sprintf($_repl_enable_done, 'consumer', $replica)
            $repl_enable_command = sprintf($_repl_enable_command, 'consumer', $_id, $repl_enable_done)

            # Command to create a replication agreement between these hosts.
            $repl_agreement_done = sprintf($_repl_agreement_done, 'consumer', $replica)
            $repl_agreement_command = sprintf($_repl_agreement_command, $replica, $replica, $repl_agreement_done)

            # Command to update parameters of the replication agreement.
            $repl_update_command = $_repl_update_command

            # NOTE: This ensures that the status is not lost when migrating from
            # spacepants/puppet-ds_389 to this module. This migration path will
            # be removed in a later version.
            exec { "Migrate replication status for consumer ${replica}: ${name}":
              command => "touch ${repl_enable_done} && touch ${repl_agreement_done} && rm -f /etc/dirsrv/slapd-${name}/consumer_${replica}.done", # lint:ignore:140chars
              path    => $ds_389::path,
              creates => $repl_enable_done,
              onlyif  => "test -f /etc/dirsrv/slapd-${name}/consumer_${replica}.done",
              require => [
                Exec["Add replication user: ${name}"],
              ],
              before  => [
                Exec["Enable replication for consumer ${replica}: ${name}"],
                Exec["Create replication agreement for consumer ${replica}: ${name}"],
              ],
            }

            exec { "Enable replication for consumer ${replica}: ${name}":
              command => $repl_enable_command,
              path    => $ds_389::path,
              creates => $repl_enable_done,
              require => [
                Exec["Add replication user: ${name}"],
              ],
            }
            -> exec { "Create replication agreement for consumer ${replica}: ${name}":
              command => $repl_agreement_command,
              path    => $ds_389::path,
              creates => $repl_agreement_done,
            }
            ~> exec { "Update replication config for consumer ${replica}: ${name}":
              command     => $repl_update_command,
              path        => $ds_389::path,
              refreshonly => true,
            }

            if $init_consumers {
              $repl_init_done = sprintf($_repl_init_done, 'consumer', $replica)
              $repl_init_command = sprintf($_repl_init_command, $replica, $repl_init_done)

              exec { "Initialize consumer ${replica}: ${name}":
                command => $repl_init_command,
                path    => $ds_389::path,
                creates => $repl_init_done,
                require => [
                  Exec["Create replication agreement for consumer ${replica}: ${name}"],
                ],
              }
            }
          }
        }
      }
    }
    # otherwise supplier (master or multi-master)
    default: {
      unless $id {
        fail('$id is required when declaring a replication supplier')
      }
      $_id = $id

      $type = 3
      $flags = 1

      if $suppliers {
        $suppliers.each |$replica| {
          if ($replica != $name) and ($replica != $facts['networking']['fqdn']) {
            # Command to enable replication for the specified suffix.
            $repl_enable_done = sprintf($_repl_enable_done, 'supplier', $replica)
            $repl_enable_command = sprintf($_repl_enable_command, 'master', $_id, $repl_enable_done)

            # Command to create a replication agreement between these hosts.
            $repl_agreement_done = sprintf($_repl_agreement_done, 'supplier', $replica)
            $repl_agreement_command = sprintf($_repl_agreement_command, $replica, $replica, $repl_agreement_done)

            # Command to update parameters of the replication agreement.
            $repl_update_command = $_repl_update_command

            # NOTE: This ensures that the status is not lost when migrating from
            # spacepants/puppet-ds_389 to this module. This migration path will
            # be removed in a later version.
            exec { "Migrate replication status for supplier ${replica}: ${name}":
              command => "touch ${repl_enable_done} && touch ${repl_agreement_done} && rm -f /etc/dirsrv/slapd-${name}/supplier_${replica}.done", # lint:ignore:140chars
              path    => $ds_389::path,
              creates => $repl_enable_done,
              onlyif  => "test -f /etc/dirsrv/slapd-${name}/supplier_${replica}.done",
              require => [
                Exec["Add replication user: ${name}"],
              ],
              before  => [
                Exec["Enable replication for supplier ${replica}: ${name}"],
                Exec["Create replication agreement for supplier ${replica}: ${name}"],
              ],
            }

            exec { "Enable replication for supplier ${replica}: ${name}":
              command => $repl_enable_command,
              path    => $ds_389::path,
              creates => $repl_enable_done,
              require => [
                Exec["Add replication user: ${name}"],
              ],
            }
            -> exec { "Create replication agreement for supplier ${replica}: ${name}":
              command => $repl_agreement_command,
              path    => $ds_389::path,
              creates => $repl_agreement_done,
            }
            ~> exec { "Update replication config for supplier ${replica}: ${name}":
              command     => $repl_update_command,
              path        => $ds_389::path,
              refreshonly => true,
            }

            if $init_suppliers {
              $repl_init_done = sprintf($_repl_init_done, 'supplier', $replica)
              $repl_init_command = sprintf($_repl_init_command, $replica, $repl_init_done)

              exec { "Initialize supplier ${replica}: ${name}":
                command => $repl_init_command,
                path    => $ds_389::path,
                creates => $repl_init_done,
                require => [
                  Exec["Create replication agreement for supplier ${replica}: ${name}"],
                ],
              }
            }
          }
        }
      }
      if $hubs {
        $hubs.each |$replica| {
          if ($replica != $name) and ($replica != $facts['networking']['fqdn']) {
            # Command to enable replication for the specified suffix.
            $repl_enable_done = sprintf($_repl_enable_done, 'hub', $replica)
            $repl_enable_command = sprintf($_repl_enable_command, 'hub', $_id, $repl_enable_done)

            # Command to create a replication agreement between these hosts.
            $repl_agreement_done = sprintf($_repl_agreement_done, 'hub', $replica)
            $repl_agreement_command = sprintf($_repl_agreement_command, $replica, $replica, $repl_agreement_done)

            # Command to update parameters of the replication agreement.
            $repl_update_command = $_repl_update_command

            # NOTE: This ensures that the status is not lost when migrating from
            # spacepants/puppet-ds_389 to this module. This migration path will
            # be removed in a later version.
            exec { "Migrate replication status for hub ${replica}: ${name}":
              command => "touch ${repl_enable_done} && touch ${repl_agreement_done} && rm -f /etc/dirsrv/slapd-${name}/hub_${replica}.done",
              path    => $ds_389::path,
              creates => $repl_enable_done,
              onlyif  => "test -f /etc/dirsrv/slapd-${name}/hub_${replica}.done",
              require => [
                Exec["Add replication user: ${name}"],
              ],
              before  => [
                Exec["Enable replication for hub ${replica}: ${name}"],
                Exec["Create replication agreement for hub ${replica}: ${name}"],
              ],
            }

            exec { "Enable replication for hub ${replica}: ${name}":
              command => $repl_enable_command,
              path    => $ds_389::path,
              creates => $repl_enable_done,
              require => [
                Exec["Add replication user: ${name}"],
              ],
            }
            -> exec { "Create replication agreement for hub ${replica}: ${name}":
              command => $repl_agreement_command,
              path    => $ds_389::path,
              creates => $repl_agreement_done,
            }
            ~> exec { "Update replication config for hub ${replica}: ${name}":
              command     => $repl_update_command,
              path        => $ds_389::path,
              refreshonly => true,
            }

            if $init_hubs {
              $repl_init_done = sprintf($_repl_init_done, 'hub', $replica)
              $repl_init_command = sprintf($_repl_init_command, $replica, $repl_init_done)

              exec { "Initialize hub ${replica}: ${name}":
                command => $repl_init_command,
                path    => $ds_389::path,
                creates => $repl_init_done,
                require => [
                  Anchor["${name}_replication_suppliers"],
                  Exec["Create replication agreement for hub ${replica}: ${name}"],
                ],
              }
            }
          }
        }
      }
      if $consumers {
        $consumers.each |$replica| {
          if ($replica != $name) and ($replica != $facts['networking']['fqdn']) {
            # Command to enable replication for the specified suffix.
            $repl_enable_done = sprintf($_repl_enable_done, 'consumer', $replica)
            $repl_enable_command = sprintf($_repl_enable_command, 'consumer', $_id, $repl_enable_done)

            # Command to create a replication agreement between these hosts.
            $repl_agreement_done = sprintf($_repl_agreement_done, 'consumer', $replica)
            $repl_agreement_command = sprintf($_repl_agreement_command, $replica, $replica, $repl_agreement_done)

            # Command to update parameters of the replication agreement.
            $repl_update_command = $_repl_update_command

            # NOTE: This ensures that the status is not lost when migrating from
            # spacepants/puppet-ds_389 to this module. This migration path will
            # be removed in a later version.
            exec { "Migrate replication status for consumer ${replica}: ${name}":
              command => "touch ${repl_enable_done} && touch ${repl_agreement_done} && rm -f /etc/dirsrv/slapd-${name}/consumer_${replica}.done", # lint:ignore:140chars
              path    => $ds_389::path,
              creates => $repl_enable_done,
              onlyif  => "test -f /etc/dirsrv/slapd-${name}/consumer_${replica}.done",
              require => [
                Exec["Add replication user: ${name}"],
              ],
              before  => [
                Exec["Enable replication for consumer ${replica}: ${name}"],
                Exec["Create replication agreement for consumer ${replica}: ${name}"],
              ],
            }

            exec { "Enable replication for consumer ${replica}: ${name}":
              command => $repl_enable_command,
              path    => $ds_389::path,
              creates => $repl_enable_done,
              require => [
                Anchor["${name}_replication_hubs"],
                Exec["Add replication user: ${name}"],
              ],
            }
            -> exec { "Create replication agreement for consumer ${replica}: ${name}":
              command => $repl_agreement_command,
              path    => $ds_389::path,
              creates => $repl_agreement_done,
            }
            ~> exec { "Update replication config for consumer ${replica}: ${name}":
              command     => $repl_update_command,
              path        => $ds_389::path,
              refreshonly => true,
            }

            if $init_consumers {
              $repl_init_done = sprintf($_repl_init_done, 'consumer', $replica)
              $repl_init_command = sprintf($_repl_init_command, $replica, $repl_init_done)

              exec { "Initialize consumer ${replica}: ${name}":
                command => $repl_init_command,
                path    => $ds_389::path,
                creates => $repl_init_done,
                require => [
                  Anchor["${name}_replication_consumers"],
                  Exec["Create replication agreement for consumer ${replica}: ${name}"],
                ],
              }
            }
          }
        }
      }
    }
  }

  # Add replication user.
  file { "/etc/dirsrv/slapd-${name}/replication-user.ldif":
    ensure  => file,
    mode    => '0440',
    owner   => $user,
    group   => $group,
    content => epp('ds_389/replication-user.epp',{
        bind_dn          => $_bind_dn,
        replication_pass => $replication_pass,
        replication_user => $replication_user,
    }),
  }
  -> exec { "Add replication user: ${name}":
    command => "ldapadd -${_opts} ${protocol}://${server_host}:${server_port} -D \"${root_dn}\" -w ${root_dn_pass} -f /etc/dirsrv/slapd-${name}/replication-user.ldif && touch /etc/dirsrv/slapd-${name}/replication-user.done", # lint:ignore:140chars
    path    => $ds_389::path,
    creates => "/etc/dirsrv/slapd-${name}/replication-user.done",
    require => [
      Ds_389::Ssl[$name],
    ],
  }

  anchor { "${name}_replication_suppliers":
    require => Exec["Add replication user: ${name}"],
  }
  anchor { "${name}_replication_hubs":
    require => Anchor["${name}_replication_suppliers"],
  }
  anchor { "${name}_replication_consumers":
    require => Anchor["${name}_replication_hubs"],
  }
}
