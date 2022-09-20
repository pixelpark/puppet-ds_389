# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased [2.6.0]

### Changed
* Update os versions and Puppet version
* Update PDK from 1.8.0 to 2.5.0

### Fixed
* Fix puppet-lint offenses

## [2.5.0] - 2021-01-20

### Added
* Add parameter `$backup_notls` to defined type `ds_389::instance`

### Changed
* Allow Puppet 7

## [2.4.0] - 2020-11-30

### Added
* Add parameter `$environment` to defined type `ds_389::backup`

### Changed
* Add PATH environment variable to default backup cron job

### Fixed
* Fix "command not found" error in backup cron job due to missing PATH variable

## [2.3.0] - 2020-11-18

### Added
* Add defined type to manage backup jobs: `ds_389::backup`

### Fixed
* Protect passwords by not displaying a diff when the password file changes

## [2.2.0] - 2020-11-16
This release fixes a major bug when using self-signed certificates. In previous
releases the internal CA certificate was created without the required
extensions. As a result, using LDAPS could lead to various SSL errors. Note
that only *new* CA certificates will benefit from this bugfix. The README
contains instructions to purge the existing SSL certificates.

### Added
* Add new dependency: camptocamp/openssl

### Changed
* Use camptocamp/openssl to generate CA certificates

### Fixed
* Fix broken CA certificates by including the required CA extensions
* Fix missing newline in cert bundle

## [2.1.0] - 2020-11-07

### Added
* Add new parameter `$options` to provide additional plugin configuration

### Fixed
* Fix resource ordering: skip plugins on error

## [2.0.0] - 2020-11-01
This is the first release after forking the module. It aims to be compatible
with spacepants/ds_389, but please read the migration notes in the README.

### Added
* Add new parameter `$create_suffix`
* Add ability to manage 389-ds plugins
* Add migration path for users of spacepants/puppet-ds_389
* Add acceptance test for multi-master replication

### Changed
* Drop legacy tool usage (setup-ds.pl)
* Migrate params.pp to Hiera module data
* Convert erb templates to epp
* Refactor SSL setup/config to use new tools wherever possible
* Refactor support for nsds5replicatedattributelist (`$excluded_attributes`)
* Refactor support for nsDS5ReplicaPurgeDelay (`$purge_delay`)
* Use modern facts instead of $::fqdn, $::hostname, etc.
* Update to PDK 1.18.1
* Limit OS support to versions that include 389-ds 1.4
* Update unit tests
* Update acceptance tests

### Fixed
* Fix resource ordering: a service restart could break the initialization of the replication

## [1.1.7] - 2018-03-13
This release fixes an issue when setting the file descriptor limit on Debian systems.

### Changed
* Fix limits config dir on Debian.

## [1.1.6] - 2018-01-29
### Summary
This release fixes a replication issue for consumers and hubs.

### Changed
* Set the replica id for consumers and hubs.

## [1.1.5] - 2018-01-19
This release adds some additional fixes for replication.

### Changed
* Fixed a bug where the nsDS5ReplicaRoot wasn't being set correctly in the replication agreement.
* Cleaned up replication attributes.
* Made the replication agreement cn more explicit.

## [1.1.4] - 2018-01-18
Fixed a bug with replication logic.

### Changed
* Check for fqdn when setting replication.

## [1.1.3] - 2018-01-18
This release adds additional support for StartTLS. ldapadd and ldapmodify actions now connect via the URI, and can connect with StartTLS via the `starttls` param. nsDS5ReplicaTransportInfo can be set to 'TLS' as well.

### Changed
* ldapadd / ldapmodify commands now connect via URI.
* ldapadd / ldapmodify commands now can connect with StartTLS.

## [1.1.2] - 2018-01-12
This release adds the ability to customize nsDS5ReplicaTransportInfo for replication. It defaults to 'LDAP', but can be set to 'SSL' via the `replica_transport` param.

### Changed
* Parameterize replication transport.
* ldapadd / ldapmodify commands now default to port 389 instead of 636.

## [1.1.1] - 2018-01-05
This release adds the ability to specify the minssf setting that controls StartTLS for non-SSL connections.

### Changed
* Parameterize nsslapd-minssf.
* Default nsslapd-minssf value changed to package default.
* ldif files are passed to ldapmodify directly instead of piping from stdout.

## [1.1.0] - 2017-12-18
This release adds the ability to manage the content of both `ds_389::add` and `ds_389::modify` ldif files. This allows for better secret management and the use of template(), inline_template(), or inline_epp() when declaring these defined types.

### Changed
* Expose the content of an ldif file to allow for template-based management.
* Clean up references to the replication manager.
* The `bind_dn_pass` param for replication has been replaced with `replication_pass`.
* Added `replication_user` which defaults to 'Replication Manager'.
* `bind_dn` is now optional, and allows the bind DN for replication to be overriden if needed.

## 1.0.0 - 2017-10-27
* Initial release.

[Unreleased]: https://github.com/markt-de/puppet-ds_389/compare/2.5.0...HEAD
[2.5.0]: https://github.com/markt-de/puppet-ds_389/compare/2.4.0...2.5.0
[2.4.0]: https://github.com/markt-de/puppet-ds_389/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/markt-de/puppet-ds_389/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/markt-de/puppet-ds_389/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/markt-de/puppet-ds_389/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/markt-de/puppet-ds_389/compare/1.1.7...2.0.0
[1.1.7]: https://github.com/markt-de/puppet-ds_389/compare/1.1.6...1.1.7
[1.1.6]: https://github.com/markt-de/puppet-ds_389/compare/1.1.5...1.1.6
[1.1.5]: https://github.com/markt-de/puppet-ds_389/compare/1.1.4...1.1.5
[1.1.4]: https://github.com/markt-de/puppet-ds_389/compare/1.1.3...1.1.4
[1.1.3]: https://github.com/markt-de/puppet-ds_389/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/markt-de/puppet-ds_389/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/markt-de/puppet-ds_389/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/markt-de/puppet-ds_389/compare/1.0.0...1.1.0
