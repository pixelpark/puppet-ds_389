require 'spec_helper'

describe 'ds_389::plugin' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specplugin' }

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          networking: { fqdn: 'foo.example.com' },
        )
      end

      context 'with required params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Set plugin specplugin to enabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://foo.example.com:389 plugin specplugin enable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done',
          )
        }
      end

      context 'when disabling a plugin' do
        let(:params) do
          {
            ensure: 'disabled',
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Set plugin specplugin to disabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://foo.example.com:389 plugin specplugin disable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done',
          )
        }
      end

      context 'with all params' do
        let(:params) do
          {
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
            server_host: 'ldap.test.org',
            server_port: 1389,
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Set plugin specplugin to enabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://ldap.test.org:1389 plugin specplugin enable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done',
          )
        }
      end
    end
  end
end
