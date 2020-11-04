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
          is_expected.to contain_exec('Set plugin specplugin state to enabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://foo.example.com:389 plugin specplugin enable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done',
          )
        }

        it {
          is_expected.not_to contain_file('/etc/dirsrv/slapd-${name}/plugin_specplugin_options')
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
          is_expected.to contain_exec('Set plugin specplugin state to disabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://foo.example.com:389 plugin specplugin disable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done',
          )
        }

        it {
          is_expected.not_to contain_file('/etc/dirsrv/slapd-${name}/plugin_specplugin_options')
        }
      end

      context 'with all params' do
        let(:params) do
          {
            ensure: 'enabled',
            options: [
              'set --groupattr uniqueMember',
              'set --allbackends on',
              'set --skipnested off',
            ],
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
            server_host: 'ldap.test.org',
            server_port: 1389,
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Set plugin specplugin state to enabled: specdirectory').with(
            command: "rm -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_disabled.done; dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://ldap.test.org:1389 plugin specplugin enable && touch /etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/plugin_specplugin_enabled.done',
          )
        }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/plugin_specplugin_options').with(
            ensure: 'file',
            mode: '0440',
            owner: 'dirsrv',
            group: 'dirsrv',
            content: '[set --groupattr uniqueMember, set --allbackends on, set --skipnested off]',
          )
        }

        it {
          is_expected.to contain_exec('Set plugin specplugin options (set --groupattr uniqueMember): specdirectory').with(
            command: "mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error && dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://ldap.test.org:1389 plugin specplugin set --groupattr uniqueMember && mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            refreshonly: true,
          ).that_subscribes_to('File[/etc/dirsrv/slapd-specdirectory/plugin_specplugin_options]')
        }
        it {
          is_expected.to contain_exec('Set plugin specplugin options (set --allbackends on): specdirectory').with(
            command: "mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error && dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://ldap.test.org:1389 plugin specplugin set --allbackends on && mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            refreshonly: true,
          ).that_subscribes_to('File[/etc/dirsrv/slapd-specdirectory/plugin_specplugin_options]')
        }
        it {
          is_expected.to contain_exec('Set plugin specplugin options (set --skipnested off): specdirectory').with(
            command: "mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error && dsconf -D 'cn=Directory Manager' -w 'supersecret' ldap://ldap.test.org:1389 plugin specplugin set --skipnested off && mv -f /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options.error /etc/dirsrv/slapd-specdirectory/plugin_specplugin_options", # rubocop:disable LineLength
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            refreshonly: true,
          ).that_subscribes_to('File[/etc/dirsrv/slapd-specdirectory/plugin_specplugin_options]')
        }
      end
    end
  end
end
