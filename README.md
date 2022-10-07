# puppet-ds_389

[![Build Status](https://github.com/markt-de/puppet-ds_389/actions/workflows/ci.yaml/badge.svg)](https://github.com/markt-de/puppet-ds_389/actions/workflows/ci.yaml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/fraenki/ds_389.svg)](https://forge.puppetlabs.com/fraenki/ds_389)
[![Puppet Forge](https://img.shields.io/puppetforge/f/fraenki/ds_389.svg)](https://forge.puppetlabs.com/fraenki/ds_389)


#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Instances](#instances)
    - [Initialize suffix](#initialize-suffix)
    - [SSL](#ssl)
    - [Plugins](#plugins)
    - [Backups](#backups)
    - [Replication overview](#replication-overview)
    - [Replication consumer](#replication-consumer)
    - [Replication hub](#replication-hub)
    - [Replication supplier](#replication-supplier)
    - [Initializing replication](#initializing-replication)
    - [Schema extensions](#schema-extensions)
    - [Modifying existing LDIF data](#modifying-existing-ldif-data)
    - [Adding new LDIF data](#adding-new-ldif-data)
    - [Adding baseline LDIF data](#adding-baseline-ldif-data)
    - [Recreate SSL certs](#recreate-ssl-certs)
1. [Reference](#reference)
1. [Limitations](#limitations)
    - [Supported versions](#supported-versions)
    - [Migrating from spacepants module](#migrating-from-spacepants-module)
1. [Development](#development)
    - [Contributing](#contributing)
    - [Fork](#fork)
1. [License](#license)

## Overview

This module installs and manages the [389 Directory Server](https://www.port389.org/). It will create and bootstrap 389 DS instances, configure SSL, replication, schema extensions and even load LDIF data.

SSL is enabled by default using self-signed certificates, but existing SSL certificates may also be used and will automatically be imported into the 389 DS instance.

Replication is supported for consumers, hubs, and suppliers (both master and multi-master), and there is a Puppet task to reinitialize replication.

## Requirements

This module requires 389-ds version 1.4 or later. Older versions are incompatible.

## Usage

### Basic usage

```puppet
include ds_389
```

At a bare minimum, the module ensures that the 389 DS base package and NSS tools are installed and sets appropiate resource limits.

### Instances

The primary resource for configuring a 389 DS service is the `ds_389::instance` define:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
}
```

In this example an instance is created with the server ID set to the hostname of the node. For a node with a hostname of `foo`, this would create an instance at `/etc/dirsrv/slapd-foo` that listens on the default ports of 389 and 636 (for SSL).

### Initialize suffix

When creating new instances, it is possible to initialize the specified suffix by using the `$create_suffix` parameter. The new instance will create a generic root node entry for the suffix in the database. This is most useful when bootstrapping a new LDAP.

### SSL

When existing SSL certificates should be used, they could be passed to the instance with the `$ssl` parameter. This parameter expects a hash with paths (either local file paths on the node or a puppet:/// path) for the PEM files for the certificate, key, and CA bundle. It also requires the certificate nickname for the cert and every CA in the bundle. (`pk12util` sets the nickname for the certificate to the friendly name of the cert in the pkcs12 bundle, and the nickname for each ca cert to `"${the common name(cn) of the ca cert subject} - ${the organization(o) of the cert issuer}"`.)

To require StartTLS for non-SSL connections, the `$minssf` parameter should be used to specify the minimum required encryption.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  minssf       => 128,
  ssl          => {
    'cert_path'      => 'puppet:///path/to/ssl_cert.pem',
    'key_path'       => 'puppet:///path/to/ssl_key.pem',
    'ca_bundle_path' => 'puppet:///path/to/ssl_ca.pem',
    'ca_cert_names'  => [
      'Certificate nickname for the first CA cert goes here',
      'Certificate nickname for another CA cert goes here',
    ],
    'cert_name'      => 'Certificate nickname goes here',
  },
}
```

### Plugins

In order to enable or disable some of the 386 DS plugins, the plugin name and a simple string should be added to the `$plugins` parameter:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  plugins      => {
    'memberof'      => 'enabled',
    'posix-winsync' => 'disabled',
  },
}
```

When additional plugin options need to be configured, a hash should be used instead:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  plugins      => {
    'memberof'      => {
      ensure  => 'enabled',
      options => [
        'set --groupattr uniqueMember',
        'set --allbackends on',
        'set --skipnested off',
      ],
    },
    'posix-winsync' => 'disabled',
  },
}
```

To use the defined type directly, the server id of the instance as well as the root dn and password must be provided:

```puppet
ds_389::plugin { 'memberof':
  ensure       => 'enabled',
  options      => [
    'set --groupattr uniqueMember',
    'set --allbackends on',
    'set --skipnested off',
  ],
  server_id    => 'example',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

### Backups

To perform online backups of a directory, the `$backup_enable` parameter should be used:

```puppet
ds_389::instance { 'example':
  backup_enable => true,
  root_dn       => 'cn=Directory Manager',
  root_dn_pass  => 'supersecret',
  suffix        => 'dc=example,dc=com',
  cert_db_pass  => 'secret',
  server_id     => $facts['networking']['hostname'],
}
```

This will enable a backup job with default parameters that is scheduled to run every night.
If the backup was successful, an empty file `/tmp/389ds_backup_success` is created and the modification time is updated. This will make it easy to monitor the status of the directory backup (by checking for the existence of the file and it's modification time).

To use the defined type directly, the server id of the instance as well as the root dn and password must be provided:

```puppet
ds_389::backup { 'Perform hourly backups of the directory':
  ensure       => 'present',
  server_id    => 'example',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  backup_dir   => '/path/to/ds-backups',
  rotate       => 10,
  time         => ['0', '*', '*'],
  success_file => '/tmp/hourly_backup_success',
}
```

### Replication overview

To set up replication, the `$replication` parameter should be used to add the replication config. At a minimum, it expects a hash with the replication bind dn, replication bind dn password, and replication role (either 'consumer', 'hub', or 'supplier').

### Replication consumer

Example config for a consumer role:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'consumer',
  },
}
```

This would ensure that the replica bind dn and credentials are present in the instance.

### Replication hub

For a hub, any consumers for the hub should be passed as an array of server IDs:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
  },
}
```

The replication agreement will then be created and added to the instance.

### Replication supplier

For a supplier, consumers need to be passed as an array, and also any hubs or other suppliers (if running in multi-master) that should be present in the instance. The replica ID for the supplier must also be provided.

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'suppliers'        => [
      'supplier1',
      'supplier2',
    ],
    'hubs'             => [
      'hub1',
      'hub2',
    ],
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
  },
}
```

### Initializing replication

Once replication has been configured on all of the desired nodes, replication can be initialized for consumers, hubs, and/or other suppliers by passing the appropriate "init_" parameters:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
  replication  => {
    'replication_pass' => 'secret',
    'role'             => 'hub',
    'suppliers'        => [
      'supplier1',
      'supplier2',
    ],
    'hubs'             => [
      'hub1',
      'hub2',
    ],
    'consumers'        => [
      'consumer1',
      'consumer2',
    ],
    'init_suppliers'   => true,
    'init_hubs'        => true,
    'init_consumers'   => true,
  },
}
```

Replication can also be initialize (or reinitialize) with the [Puppet task](#reference).

### Schema extensions

If a schema extension needs to be added, the `$schema_extensions` parameter should be used. This parameter expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node):

```puppet
ds_389::instance { 'example':
  root_dn           => 'cn=Directory Manager',
  root_dn_pass      => 'supersecret',
  suffix            => 'dc=example,dc=com',
  cert_db_pass      => 'secret',
  schema_extensions => {
    '99example_schema' => 'puppet:///path/to/example_schema.ldif',
  },
}
```

Note that schema filenames are typically prefixed with a number that indicates the desired schema load order.

### Modifying existing LDIF data

If the default ldif data (typically configs) needs to be modified, the `$modify_ldifs` parameter should be used. This parameter expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node):

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  modify_ldifs => {
    'example_ldif_modify' => 'puppet:///path/to/example_modify.ldif',
  },
}
```

The ldif file is then created and passed to ldapmodify to load it into the instance.

To use the defined type directly, by calling their define directly, but the server id of the instance as well as the root dn and password must be provided:

```puppet
ds_389::modify { 'example_ldif_modify':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_modify.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

### Adding new LDIF data

If new ldif data (typically configs) needs to be added, the `$add_ldifs` parameter should be used. This parameter expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node):

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  add_ldifs    => {
    'example_ldif_add' => 'puppet:///path/to/example_add.ldif',
  },
}
```

This works similar to the modify_ldifs parameter, but it utilizes `ldapadd` instead of `ldapmodify`.

To use the defined type directly, the server id of the instance as well as the root dn and password must be provided:

```puppet
ds_389::add { 'example_ldif_add':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_add.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

### Adding baseline LDIF data

To load baseline ldif data that runs after any other ldif configuration changes, the `$base_load_ldifs` parameter should be used:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  base_load_ldifs    => {
    'example_ldif_baseline' => 'puppet:///path/to/example_baseline.ldif',
  },
}
```

Note that while it's possible declare these via the `ds_389::add` defined type, Puppet's resource load ordering may potentially result in it attempting to add the ldif before a configuration change that it requires.

### Recreate SSL certs

Currently some manual steps are required to regenerate the SSL certificates. A new Bolt task would be nice, PRs are welcome. :)

A backup should be created before attempting this procedure.

The following shell commands need to be run as root to remove the existing certificates:

```shell
export LDAP_INSTANCE="my-instance-name"

test -d /etc/dirsrv/slapd-${LDAP_INSTANCE} || exit 1

systemctl stop dirsrv@${LDAP_INSTANCE}

dd if=/dev/random count=1024 | sha256sum | awk '{print $1}' > /tmp/noisefile-${LDAP_INSTANCE}
cut -d: -f2 /etc/dirsrv/slapd-${LDAP_INSTANCE}/pin.txt > /tmp/passfile-${LDAP_INSTANCE}

rm -f /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}CA.cnf \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}CA-Key.pem \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}CA.p12 \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}CA.pem \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}Cert-Key.pem \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/${LDAP_INSTANCE}Cert.pem \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/ssl_config.done \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/ssl.done \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/ssl_enable.done \
  /etc/dirsrv/slapd-${LDAP_INSTANCE}/ssl.ldif

certutil -D -n "${LDAP_INSTANCE}Cert" -d /etc/dirsrv/slapd-${LDAP_INSTANCE}
certutil -D -n "${LDAP_INSTANCE}CA" -d /etc/dirsrv/slapd-${LDAP_INSTANCE}
```

Next the file `/etc/dirsrv/slapd-${LDAP_INSTANCE}/dse.ldif` needs to be modified and the following entries including their attributes must be removed:

```
  cn=AES,cn=encrypted attribute keys,cn=database_name,cn=ldbm database,cn=plugins,cn=config
  cn=3DES,cn=encrypted attribute keys,cn=database_name,cn=ldbm database,cn=plugins,cn=config
```

Afterwards Puppet should be used to regenerate both the CA and the server certificates.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

### Supported versions

This module requires 389-ds version 1.4 or later. When using an older version of 389-ds, consider using [spacepants/puppet-ds_389](https://github.com/spacepants/puppet-ds_389) instead. It is no longer under active development, but it may still be useful to migrate to an up-to-date version of 389-ds.

In newer versions of 389-ds the "master" role was renamed to "supplier" in an [backwards-incompatible way](https://github.com/389ds/389-ds-base/issues/4656). The `$supplier_role_name` parameter can be used to change the role name accordingly.

### Migrating from spacepants module

Version 2.x of this module contains migration tasks for users of [spacepants/puppet-ds_389](https://github.com/spacepants/puppet-ds_389). They will ensure that the SSL status as well as the replication status of suppliers, hubs and consumers is preserved. However, it is strongly recommended to setup a test environment or at least run Puppet Agent with `--noop` when migrating to this module.

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

Contributions must pass all existing tests, new features should provide additional unit/acceptance tests.

## License

Copyright 2020-2022 Frank Wall

Copyright 2019 Paul Bailey
