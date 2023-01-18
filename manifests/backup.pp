# @summary Setup backup jobs for a 389 ds instance.
#
# @example
#   ds_389::backup { 'daily backup':
#     root_dn      => 'cn=Directory Manager',
#     root_dn_pass => 'supersecure',
#     server_id    => 'instancename',
#   }
#
# @param backup_dir
#   The directory where the backup files will be stored. The directory must
#   be read- and writable for the 389-ds user. Default: `/var/lib/dirsrv/slapd-instance/bak`
#
# @param ensure
#   This parameter controls whether the backup job should be created (`present`)
#   or removed (`absent`).
#
# @param environment
#   Any environment settings associated with the backup cron job. Note that the
#   PATH variable is automatically added to the environment.
#
# @param protocol
#   The protocol to use when performing the backup.
#
# @param root_dn_pass
#   The password to use when performing the backup. Required.
#
# @param root_dn
#   The bind DN to use when performing the backup. Required.
#
# @param rotate
#   The maximum backup age in days. Older backups will be removed.
#
# @param time 
#   An array containing the cron schedule in this order: minute, hour, weekday.
#
# @param server_host
#   The host to use when performing the backup. Default: `$facts['networking']['fqdn']`
#
# @param server_id
#   The 389 ds instance name. Required.
#
# @param server_port
#   The port to use when performing the backup. Default: 636
#
# @param success_file
#   Specify a path where upon successful backup a file should be created for checking purposes.
#
define ds_389::backup (
  String $root_dn,
  Variant[String,Sensitive[String]] $root_dn_pass,
  String $server_id,
  String $ensure = 'present',
  Array $environment = [],
  Enum['ldap','ldaps'] $protocol = 'ldaps',
  Integer $rotate = 30,
  Array $time = ['15', '23', '*'],
  String $server_host = $facts['networking']['fqdn'],
  Integer $server_port = 636,
  Stdlib::Absolutepath $success_file = '/tmp/389ds_backup_success',
  Optional[Stdlib::Absolutepath] $backup_dir = undef,
) {
  include ds_389

  if ($backup_dir) {
    $real_backup_dir = $backup_dir
  } else {
    $real_backup_dir = "/var/lib/dirsrv/slapd-${server_id}/bak"
  }

  # Create backup directory.
  file { $real_backup_dir:
    ensure => 'directory',
    mode   => '0770',
    owner  => $ds_389::user,
    group  => $ds_389::group,
  }

  # Generate a simplified version of the name which will be used
  # to create unique filenames.
  $jobname = regsubst($name, '[^a-zA-Z0-9_]', '', 'G')

  # For security reasons a password file is created instead of specifying
  # the password on the command line.
  $passfile = "/etc/dirsrv/slapd-${server_id}/backup_passwd.${jobname}"
  file { $passfile:
    ensure    => $ensure,
    mode      => '0640',
    owner     => $ds_389::user,
    group     => $ds_389::group,
    content   => inline_epp('<%= $pass %>', { pass => $root_dn_pass }),
    show_diff => false,
  }

  # Set environment variables for the cron job.
  if ($environment) {
    $_environment = $environment + ["PATH=${ds_389::path}"]
  } else {
    $_environment = ["PATH=${ds_389::path}"]
  }

  # Command to perform all backup and cleanup tasks.
  $backup_command = join([
      # Create tasks to perform the backup.
      'dsconf',
      "-D \'${root_dn}\'",
      "-y \'${passfile}\'",
      "${protocol}://${server_host}:${server_port}",
      'backup create',
      $backup_dir,
      # Create success file upon successful backup.
      "&& touch ${success_file}",
      # Command to remove outdated backups. No cleanup is performed if the
      # backup fails.
      "&& find \'${real_backup_dir}/\' -mindepth 1 -maxdepth 1 -mtime +${rotate} -print0 | xargs -0 -r rm -rf",
  ], ' ')

  cron { "Backup job for ${server_id}: ${name}":
    ensure      => $ensure,
    command     => $backup_command,
    user        => $ds_389::user,
    environment => $_environment,
    minute      => $time[0],
    hour        => $time[1],
    weekday     => $time[2],
  }
}
