require 'spec_helper'

describe 'ds_389::replication' do
  let(:pre_condition) do
    'include ::ds_389
    ::ds_389::ssl{ "specdirectory":
      cert_name    => "foo.example.com",
      root_dn      => "cn=Directory Manager",
      root_dn_pass => "supersecure",
    }'
  end
  let(:title) { 'specdirectory' }

  # content blocks
  let(:consumer_default) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:consumer_custom) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:hub_default) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:hub_custom) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:supplier_default) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:supplier_custom) do
    'dn: cn=Replication Manager,cn=config
objectClass: inetorgperson
objectClass: person
objectClass: top
cn: Replication Manager
givenName: Replication
sn: Manager
userPassword: supersecret
passwordExpirationTime: 20380119031407Z
nsIdleTimeout: 0
'
  end

  let(:consumer1_agreement) do
    'dn: cn=specdirectory to consumer1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to consumer1 agreement
nsDS5ReplicaHost: consumer1
nsDS5ReplicaPort: 389
nsDS5ReplicaTransportInfo: LDAP
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=example,dc=com
description: replication agreement from specdirectory to consumer1
'
  end

  let(:consumer1_agreement_custom) do
    'dn: cn=specdirectory to consumer1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to consumer1 agreement
nsDS5ReplicaHost: consumer1
nsDS5ReplicaPort: 1636
nsDS5ReplicaTransportInfo: SSL
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=test,dc=org
description: replication agreement from specdirectory to consumer1
'
  end

  let(:hub1_agreement) do
    'dn: cn=specdirectory to hub1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to hub1 agreement
nsDS5ReplicaHost: hub1
nsDS5ReplicaPort: 389
nsDS5ReplicaTransportInfo: LDAP
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=example,dc=com
description: replication agreement from specdirectory to hub1
'
  end

  let(:hub1_agreement_custom) do
    'dn: cn=specdirectory to hub1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to hub1 agreement
nsDS5ReplicaHost: hub1
nsDS5ReplicaPort: 1636
nsDS5ReplicaTransportInfo: SSL
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=test,dc=org
description: replication agreement from specdirectory to hub1
'
  end

  let(:supplier1_agreement) do
    'dn: cn=specdirectory to supplier1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to supplier1 agreement
nsDS5ReplicaHost: supplier1
nsDS5ReplicaPort: 389
nsDS5ReplicaTransportInfo: LDAP
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=example,dc=com
description: replication agreement from specdirectory to supplier1
'
  end

  let(:supplier1_agreement_custom) do
    'dn: cn=specdirectory to supplier1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
objectClass: top
objectClass: nsDS5ReplicationAgreement
cn: specdirectory to supplier1 agreement
nsDS5ReplicaHost: supplier1
nsDS5ReplicaPort: 1636
nsDS5ReplicaTransportInfo: SSL
nsDS5ReplicaBindDN: cn=Replication Manager,cn=config
nsDS5ReplicaBindMethod: SIMPLE
nsDS5ReplicaCredentials: supersecret
nsDS5ReplicaRoot: dc=test,dc=org
description: replication agreement from specdirectory to supplier1
'
  end

  let(:consumer1_init) do
    'dn: cn=specdirectory to consumer1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  let(:consumer1_init_custom) do
    'dn: cn=specdirectory to consumer1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  let(:hub1_init) do
    'dn: cn=specdirectory to hub1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  let(:hub1_init_custom) do
    'dn: cn=specdirectory to hub1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  let(:supplier1_init) do
    'dn: cn=specdirectory to supplier1 agreement,cn=replica,cn="dc=example,dc=com",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  let(:supplier1_init_custom) do
    'dn: cn=specdirectory to supplier1 agreement,cn=replica,cn="dc=test,dc=org",cn=mapping tree,cn=config
changetype: modify
replace: nsDS5BeginReplicaRefresh
nsDS5BeginReplicaRefresh: start
'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          networking: { fqdn: 'foo.example.com' },
        )
      end

      context 'when setting up a consumer' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'consumer',
              suffix: 'dc=example,dc=com',
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication-user.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: consumer_default,
            )
          }
          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -xH ldap://foo.example.com:389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }

          it { is_expected.to contain_anchor('specdirectory_replication_suppliers').that_requires('Exec[Add replication user: specdirectory]') }
          it { is_expected.to contain_anchor('specdirectory_replication_hubs').that_requires('Anchor[specdirectory_replication_suppliers]') }
          it { is_expected.to contain_anchor('specdirectory_replication_consumers').that_requires('Anchor[specdirectory_replication_hubs]') }
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'consumer',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              starttls: true,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication-user.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: consumer_custom,
            )
          }
          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -ZxH ldap://ldap.test.org:1389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }
        end
      end

      context 'when setting up a hub' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'hub',
              suffix: 'dc=example,dc=com',
              consumers: ['consumer1', 'specdirectory'],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication-user.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: hub_default,
            )
          }
          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -xH ldap://foo.example.com:389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }

          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_exec('Enable replication for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 replication enable --suffix 'dc=example,dc=com' --role=consumer --replica-id=65535 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt create --suffix='dc=example,dc=com' --host='consumer1' --port=389 --conn-protocol=LDAP --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt set --suffix='dc=example,dc=com'  --repl-purge-delay='604800' 'specdirectory to consumer1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'hub',
                suffix: 'dc=example,dc=com',
                consumers: ['consumer1'],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt init --suffix='dc=example,dc=com' 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done", # rubocop:disable LineLength
                path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'Exec[Create replication agreement for consumer consumer1: specdirectory]',
                ],
              )
            }
          end
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'hub',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1636,
              protocol: 'ldaps',
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              consumers: ['consumer1', 'specdirectory'],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication-user.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'custom_user',
              group: 'custom_group',
              content: hub_custom,
            )
          }
          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -xH ldaps://ldap.test.org:1636 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }

          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_exec('Enable replication for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldaps://ldap.test.org:1636 replication enable --suffix 'dc=test,dc=org' --role=consumer --replica-id=65535 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldaps://ldap.test.org:1636 repl-agmt create --suffix='dc=test,dc=org' --host='consumer1' --port=1636 --conn-protocol=SSL --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldaps://ldap.test.org:1636 repl-agmt set --suffix='dc=test,dc=org'  --repl-purge-delay='604800' 'specdirectory to consumer1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'hub',
                suffix: 'dc=test,dc=org',
                server_host: 'ldap.test.org',
                server_port: 1389,
                replica_port: 1636,
                replica_transport: 'SSL',
                user: 'custom_user',
                group: 'custom_group',
                consumers: ['consumer1'],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt init --suffix='dc=test,dc=org' 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done", # rubocop:disable LineLength
                path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'Exec[Create replication agreement for consumer consumer1: specdirectory]',
                ],
              )
            }
          end
        end
      end

      context 'when setting up a supplier' do
        context 'with required parameters' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=example,dc=com',
              id: 1,
              suppliers: ['supplier1', 'specdirectory'],
              hubs: ['hub1', 'specdirectory'],
              consumers: ['consumer1', 'specdirectory'],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/replication-user.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: supplier_default,
            )
          }
          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -xH ldap://foo.example.com:389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }

          it { is_expected.not_to contain_exec('Create replication agreement for supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Create replication agreement for hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Create replication agreement for consumer specdirectory: specdirectory') }

          it {
            is_expected.to contain_exec('Enable replication for supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 replication enable --suffix 'dc=example,dc=com' --role=master --replica-id=1 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt create --suffix='dc=example,dc=com' --host='supplier1' --port=389 --conn-protocol=LDAP --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to supplier1 agreement' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Enable replication for hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 replication enable --suffix 'dc=example,dc=com' --role=hub --replica-id=1 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt create --suffix='dc=example,dc=com' --host='hub1' --port=389 --conn-protocol=LDAP --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to hub1 agreement' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Enable replication for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 replication enable --suffix 'dc=example,dc=com' --role=consumer --replica-id=1 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt create --suffix='dc=example,dc=com' --host='consumer1' --port=389 --conn-protocol=LDAP --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt set --suffix='dc=example,dc=com'  --repl-purge-delay='604800' 'specdirectory to consumer1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          context 'when initializing suppliers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: ['supplier1', 'specdirectory'],
                hubs: ['hub1', 'specdirectory'],
                consumers: ['consumer1', 'specdirectory'],
                init_suppliers: true,
              }
            end

            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

            it {
              is_expected.to contain_exec('Initialize supplier supplier1: specdirectory').with(
                command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt init --suffix='dc=example,dc=com' 'specdirectory to supplier1 agreement' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done", # rubocop:disable LineLength
                path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done',
              ).that_requires(
                [
                  'Exec[Create replication agreement for supplier supplier1: specdirectory]',
                ],
              )
            }
          end

          context 'when initializing hubs' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: ['supplier1', 'specdirectory'],
                hubs: ['hub1', 'specdirectory'],
                consumers: ['consumer1', 'specdirectory'],
                init_hubs: true,
              }
            end

            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

            it {
              is_expected.to contain_exec('Initialize hub hub1: specdirectory').with(
                command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt init --suffix='dc=example,dc=com' 'specdirectory to hub1 agreement' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_init.done", # rubocop:disable LineLength
                path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_init.done',
              ).that_requires(
                [
                  'Exec[Create replication agreement for hub hub1: specdirectory]',
                ],
              )
            }
          end

          context 'when initializing consumers' do
            let(:params) do
              {
                replication_pass: 'supersecret',
                root_dn: 'cn=Directory Manager',
                root_dn_pass: 'supersecure',
                role: 'supplier',
                suffix: 'dc=example,dc=com',
                id: 1,
                suppliers: ['supplier1', 'specdirectory'],
                hubs: ['hub1', 'specdirectory'],
                consumers: ['consumer1', 'specdirectory'],
                init_consumers: true,
              }
            end

            it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

            it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
            it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }

            it {
              is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
                command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://foo.example.com:389 repl-agmt init --suffix='dc=example,dc=com' 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done", # rubocop:disable LineLength
                path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
                creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
              ).that_requires(
                [
                  'Exec[Create replication agreement for consumer consumer1: specdirectory]',
                ],
              )
            }
          end
        end

        context 'with parameter overrides' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              purge_delay: 9999,
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: ['supplier1', 'specdirectory'],
              hubs: ['hub1', 'specdirectory'],
              consumers: ['consumer1', 'specdirectory'],
              excluded_attributes: ['authorityRevocationList', 'accountUnlockTime', 'memberof'],
            }
          end

          it { is_expected.to compile }

          it {
            is_expected.to contain_exec('Add replication user: specdirectory').with(
              command: 'ldapadd -xH ldap://ldap.test.org:1389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/replication-user.ldif && touch /etc/dirsrv/slapd-specdirectory/replication-user.done', # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/replication-user.done',
            ).that_requires('File[/etc/dirsrv/slapd-specdirectory/replication-user.ldif]')
          }

          it { is_expected.not_to contain_exec('Create replication agreement for supplier specdirectory: specdirectory') }

          it {
            is_expected.to contain_exec('Enable replication for supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 replication enable --suffix 'dc=test,dc=org' --role=master --replica-id=100 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt create --suffix='dc=test,dc=org' --host='supplier1' --port=1636 --conn-protocol=SSL --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to supplier1 agreement' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt set --suffix='dc=test,dc=org' --frac-list='authorityRevocationList accountUnlockTime memberof' --repl-purge-delay='9999' 'specdirectory to supplier1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it {
            is_expected.to contain_exec('Enable replication for hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 replication enable --suffix 'dc=test,dc=org' --role=hub --replica-id=100 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt create --suffix='dc=test,dc=org' --host='hub1' --port=1636 --conn-protocol=SSL --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to hub1 agreement' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt set --suffix='dc=test,dc=org' --frac-list='authorityRevocationList accountUnlockTime memberof' --repl-purge-delay='9999' 'specdirectory to hub1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it {
            is_expected.to contain_exec('Enable replication for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 replication enable --suffix 'dc=test,dc=org' --role=consumer --replica-id=100 --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_enable.done',
            ).that_requires(
              [
                'Exec[Add replication user: specdirectory]',
              ],
            )
          }

          it {
            is_expected.to contain_exec('Create replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt create --suffix='dc=test,dc=org' --host='consumer1' --port=1636 --conn-protocol=SSL --bind-dn='cn=Replication Manager,cn=config' --bind-passwd='supersecret' --bind-method=SIMPLE 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_agreement.done',
            )
          }

          it {
            is_expected.to contain_exec('Update replication agreement for consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt set --suffix='dc=test,dc=org' --frac-list='authorityRevocationList accountUnlockTime memberof' --repl-purge-delay='9999' 'specdirectory to consumer1 agreement'", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }

          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }
        end

        context 'when initializing suppliers' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: ['supplier1', 'specdirectory'],
              hubs: ['hub1', 'specdirectory'],
              consumers: ['consumer1', 'specdirectory'],
              init_suppliers: true,
            }
          end

          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          it {
            is_expected.to contain_exec('Initialize supplier supplier1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt init --suffix='dc=test,dc=org' 'specdirectory to supplier1 agreement' && touch /etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/supplier_supplier1_init.done',
            ).that_requires(
              [
                'Exec[Create replication agreement for supplier supplier1: specdirectory]',
              ],
            )
          }
        end

        context 'when initializing hubs' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: ['supplier1', 'specdirectory'],
              hubs: ['hub1', 'specdirectory'],
              consumers: ['consumer1', 'specdirectory'],
              init_hubs: true,
            }
          end

          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer consumer1: specdirectory') }

          it {
            is_expected.to contain_exec('Initialize hub hub1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt init --suffix='dc=test,dc=org' 'specdirectory to hub1 agreement' && touch /etc/dirsrv/slapd-specdirectory/hub_hub1_init.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/hub_hub1_init.done',
            ).that_requires(
              [
                'Exec[Create replication agreement for hub hub1: specdirectory]',
              ],
            )
          }
        end

        context 'when initializing consumers' do
          let(:params) do
            {
              replication_pass: 'supersecret',
              root_dn: 'cn=Directory Manager',
              root_dn_pass: 'supersecure',
              role: 'supplier',
              suffix: 'dc=test,dc=org',
              server_host: 'ldap.test.org',
              server_port: 1389,
              replica_port: 1636,
              replica_transport: 'SSL',
              user: 'custom_user',
              group: 'custom_group',
              id: 100,
              suppliers: ['supplier1', 'specdirectory'],
              hubs: ['hub1', 'specdirectory'],
              consumers: ['consumer1', 'specdirectory'],
              init_consumers: true,
            }
          end

          it { is_expected.not_to contain_exec('Initialize supplier specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub specdirectory: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize consumer specdirectory: specdirectory') }

          it { is_expected.not_to contain_exec('Initialize supplier supplier1: specdirectory') }
          it { is_expected.not_to contain_exec('Initialize hub hub1: specdirectory') }

          it {
            is_expected.to contain_exec('Initialize consumer consumer1: specdirectory').with(
              command: "dsconf -D 'cn=Directory Manager' -w 'supersecure' ldap://ldap.test.org:1389 repl-agmt init --suffix='dc=test,dc=org' 'specdirectory to consumer1 agreement' && touch /etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done", # rubocop:disable LineLength
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              creates: '/etc/dirsrv/slapd-specdirectory/consumer_consumer1_init.done',
            ).that_requires(
              [
                'Exec[Create replication agreement for consumer consumer1: specdirectory]',
              ],
            )
          }
        end
      end
    end
  end
end
