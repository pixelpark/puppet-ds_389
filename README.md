# puppet-ds_389

[![Build Status](https://travis-ci.org/markt-de/puppet-ds_389.png?branch=master)](https://travis-ci.org/markt-de/puppet-ds_389)
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
    - [Replication overview](#replication-overview)
    - [Replication consumer](#replication-consumer)
    - [Replication hub](#replication-hub)
    - [Replication supplier](#replication-supplier)
    - [Initializing replication](#initializing-replication)
    - [Schema extensions](#schema-extensions)
    - [Modifying existing LDIF data](#modifying-existing-ldif-data)
    - [Adding new LDIF data](#adding-new-ldif-data)
    - [Adding baseline LDIF data](#adding-baseline-ldif-data)
1. [Reference](#reference)
1. [Development](#development)
    - [Contributing](#contributing)
    - [Fork](#fork)
1. [License](#license)

## Overview

This module allows you to install and manage [389 Directory Server](https://www.port389.org/), create and bootstrap 389 DS instances, configure SSL, replication, schema extensions and even load LDIF data.

SSL is enabled by default. If you already have an SSL cert you can provide the cert, key, and CA bundle, and they will be imported into your instance. Otherwise, it will generate self-signed certificates. Replication is supported for consumers, hubs, and suppliers (both master and multi-master), and there is a Puppet task to reinitialize replication.

## Requirements

This module requires 389-ds version 1.4 or later. Older versions are incompatible.

## Usage

### Basic usage

```puppet
include ds_389
```

At a bare minimum, the module ensures that the 389 DS base package and NSS tools are installed, and increases the file descriptors for 389 DS.

You will probably also want to create a 389 DS instance, though, which you can do by declaring a `ds_389::instance` resource:

```puppet
ds_389::instance { 'example':
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
  suffix       => 'dc=example,dc=com',
  cert_db_pass => 'secret',
  server_id    => $facts['networking']['hostname'],
}
```

### Instances

The primary resource for configuring 389 DS is the `ds_389::instance` define.

In our previous example, we created an instance with the server ID set to the hostname of the node. For a node with a hostname of `foo`, this would create an instance at `/etc/dirsrv/slapd-foo` that listens on the default ports of 389 and 636 (for SSL).

### Initialize suffix

When creating new instances, it is possible to initialize the specified suffix by using the `$create_suffix` parameter. The new instance will create a generic root node entry for the suffix in the database. This is most useful when bootstrapping a new LDAP.

### SSL

If you have existing SSL certificates you would like to use, you could pass them in to the instance with the `ssl` parameter. It expects a hash with paths (either local file paths on the node or a puppet:/// path) for the PEM files for your certificate, key, and CA bundle. It also requires the certificate nickname for the cert and every CA in the bundle. (`pk12util` sets the nickname for the certificate to the friendly name of the cert in the pkcs12 bundle, and the nickname for each ca cert to "${the common name(cn) of the ca cert subject} - ${the organization(o) of the cert issuer}".)

To require StartTLS for non-SSL connections, you can pass in the `minssf` param to specify the minimum required encryption.

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

### Replication overview

If you need to set up replication, you could pass in the replication config via the `replication` parameter. At a minimum, it expects a hash with the replication bind dn, replication bind dn password, and replication role (either 'consumer', 'hub', or 'supplier').

### Replication consumer

For a consumer, with our previous example:

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

For a hub, you can also pass in any consumers for the hub as an array of server IDs, and the replication agreement will be created and added to the instance.

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

### Replication supplier

For a supplier, you can pass in consumers, and also any hubs or other suppliers (if running in multi-master) that should be present in the instance. You will also need to provide the replica ID for the supplier.

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

Once replication has been configured on all of the desired nodes, you can initialize replication for consumers, hubs, and/or other suppliers by passing the appropriate parameters.

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

You can also initialize (or reinitialize) replication with the [Puppet task](#reference).

### Schema extensions

If you need to add any schema extensions, you can can pass those in with the `schema_extensions` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). Note that schema filenames are typically prefixed with a number that indicates the desired schema load order.

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

### Modifying existing LDIF data

If you need to modify any of the default ldif data (typically configs), you can do so via the `modify_ldifs` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). The ldif file is created and passed to ldapmodify to load it into the instance.

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

You can also declare those separately, by calling their define directly, but you'll need to provide the server id of the instance as well as the root dn and password.

```puppet
ds_389::modify { 'example_ldif_modify':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_modify.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

### Adding new LDIF data

If you need to add any new ldif data (typically configs), you can do so via the `add_ldifs` parameter. It expects a hash with the desired ldif filename as the key, and a source reference (either via puppet:/// or an absolute path on the node). These function similarly to the modify_ldifs param, but are passed to ldapadd instead of ldapmodify.

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

You can also declare those separately, by calling their define directly, but you will need to provide the server id of the instance as well as the root dn and password.

```puppet
ds_389::add { 'example_ldif_add':
  server_id    => 'example',
  source       => 'puppet:///path/to/example_add.ldif',
  root_dn      => 'cn=Directory Manager',
  root_dn_pass => 'supersecret',
}
```

### Adding baseline LDIF data

If you need to load baseline ldif data that runs after any other ldif configuration changes, you can pass those in via the `base_load_ldifs` parameter.

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

Note that while you can declare these via the `ds_389::add` define, puppet's resource load ordering may potentially result in it attempting to add the ldif before a configuration change that it requires.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

### Classes

#### Public classes

* `ds_389`: Main class, manages the installation and configuration of 389-ds-base.

#### Private classes

* `ds_389::install`: Installs 389-ds-base.
* `ds_389::params`: Sets parameters according to platform.

#### Defined types

* `ds_389::instance`: The primary defined type. Creates and manages a 389 DS instance.
* `ds_389::add`: Adds ldif data via ldapadd to a 389 DS instance.
* `ds_389::modify`: Modifies ldif data via ldapmodify for a 389 DS instance.

The following defines are typically called from an instance.

* `ds_389::replication`: Sets up replication for a 389 DS instance.
* `ds_389::schema`: Adds a schema extension to a 389 DS instance.
* `ds_389::service`: Manages the service for a 389 DS instance.
* `ds_389::ssl`: Enables SSL for a 389 DS instance.

### Tasks
* `ds_389::reinit_consumer`: Reinitializes replication on a node.

### Parameters

#### ds_389::modify
* `server_id`: The 389 ds instance name. _Required._
* `content`: The file content to use for the ldif file. _Required, unless providing the source._
* `source`: The source path to use for the ldif file. _Required, unless providing the content._
* `root_dn`: The bind DN to use when calling ldapmodify. _Required._
* `root_dn_pass`: The password to use when calling ldapmodify. _Required._
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_port`: The port to use when calling ldapmodify. _Default: 389_
* `protocol`: The protocol to use when calling ldapmodify. _Default: 'ldap'_
* `starttls`: Whether to use StartTLS when calling ldapmodify. _Default: false_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*

#### ds_389::replication
* `replication_pass`: The bind dn password of the replication user. _Required._
* `root_dn`: The root dn for configuring replication. _Required._
* `root_dn_pass`: The root dn password for configuring replication. _Required._
* `role`: Replication role. Either 'supplier', 'hub', or 'consumer'. _Required._
* `suffix`: The LDAP suffix to use. _Required._
* `replication_user`: The name of the replication user. _Default: 'Replication Manager'_
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_port`: The port to use when calling ldapmodify. _Default: 389_
* `protocol`: The protocol to use when calling ldapmodify. _Default: 'ldap'_
* `starttls`: Whether to use StartTLS when calling ldapmodify. _Default: false_
* `replica_port`: The port to use for replication. _Default: 389_
* `replica_transport`: The transport type to use for replication. _Default: LDAP_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*
* `id`: The replica id. _Optional unless declaring a supplier._
* `purge_delay`: Time in seconds state information stored in replica entries is retained. _Default: 604800_
* `bind_dn`: The bind dn of the replication user. _Optional._
* `suppliers`: An array of supplier names to ensure. _Optional._
* `hubs`: An array of hub names to ensure. _Optional._
* `consumers`: An array of consumer names to ensure. _Optional._
* `excluded_attributes`: An array of attributes to exclude from replication. _Optional._
* `init_suppliers`: Whether to initialize replication for suppliers. _Default: false_
* `init_hubs`: Whether to initialize replication for hubs. _Default: false_
* `init_consumers`: Whether to initialize replication for consumers. _Default: false_

#### ds_389::schema
* `server_id`: The 389 ds instance name. _Required._
* `source`: The source path to use for the ldif file. _Required._
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*

#### ds_389::service
* `service_ensure`: The state the service should be in. _Default: 'running'_
* `service_enable`: Whether the service should be enabled. _Default: true_

#### ds_389::ssl
* `cert_name`: The nickname of the SSL cert to use. _Required._
* `root_dn`: The bind DN to use when calling ldapmodify. _Required._
* `root_dn_pass`: The password to use when calling ldapmodify. _Required._
* `server_host`: The host to use when calling ldapmodify. _Default: $::fqdn_
* `server_port`: The port to use when calling ldapmodify. _Default: 389_
* `server_ssl_port`: The port to use for SSL traffic. _Default: 636_
* `user`: The owner of the created ldif file. *Default: $::ds_389::user*
* `group`: The group of the created ldif file. *Default: $::ds_389::group*
* `minssf`: The minimum security strength for connections. _Default: 0_
* `ssl_version_min`: The minimum TLS version to allow. _Default: 'TLS1.1'_

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

Contributions must pass all existing tests, new features should provide additional unit/acceptance tests.

### License

Copyright 2020 Frank Wall
Copyright 2019 Paul Bailey
