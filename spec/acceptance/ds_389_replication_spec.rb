require 'spec_helper_acceptance'

if ENV['RUN_TEST'] == 'replication'

  describe 'ds_389 replication' do
    context 'in multi-master mode' do
      # Using puppet_apply as a helper
      it 'is expected to work with no errors' do
        pp = <<-EOS
        class { 'ds_389':
          instances => {
            'ldap01' => {
              'root_dn'           => 'cn=Directory Manager',
              'root_dn_pass'      => 'supersecret',
              'suffix'            => 'dc=example,dc=com',
              'cert_db_pass'      => 'secret',
              'server_id'         => 'ldap01',
              'server_host'       => '127.0.0.1',
              'server_port'       => 389,
              'server_ssl_port'   => 636,
              'replication'       => {
                'id'                => 1,
                'init_suppliers'    => false,
                'replication_pass'  => 'replsecret',
                'replica_port'      => 1389,
                'role'              => 'supplier',
                'suppliers'         => ['127.0.0.1'],
              },
            },
            'ldap02' => {
              'root_dn'           => 'cn=Directory Manager',
              'root_dn_pass'      => 'supersecret',
              'suffix'            => 'dc=example,dc=com',
              'cert_db_pass'      => 'secret',
              'server_id'         => 'ldap02',
              'server_host'       => '127.0.0.1',
              'server_port'       => 1389,
              'server_ssl_port'   => 1636,
              'replication'       => {
                'id'                => 2,
                'init_suppliers'    => true,
                'replication_pass'  => 'replsecret',
                'replica_port'      => 389,
                'role'              => 'supplier',
                'suppliers'         => ['127.0.0.1'],
              },
            },
          },
        }
        EOS

        # Run it twice and test for idempotency
        apply_manifest(pp, catch_failures: true)
        # apply_manifest(pp, catch_changes: true)

        # Wait for initialization to complete.
        sleep 60
      end

      describe port(389) do
        it { is_expected.to be_listening }
      end

      describe port(1389) do
        it { is_expected.to be_listening }
      end

      describe port(636) do
        it { is_expected.to be_listening }
      end

      describe port(1636) do
        it { is_expected.to be_listening }
      end

      describe service('dirsrv@ldap01') do
        it { is_expected.to be_enabled }
        it { is_expected.to be_running }
      end

      describe service('dirsrv@ldap02') do
        it { is_expected.to be_enabled }
        it { is_expected.to be_running }
      end

      describe file('/var/log/dirsrv/slapd-ldap01/errors') do
        its(:content) { is_expected.to match %r{enabling replication} }
      end

      describe file('/var/log/dirsrv/slapd-ldap02/errors') do
        its(:content) { is_expected.to match %r{Rebuilding replication changelog RUV complete} }
      end
    end
  end
end
