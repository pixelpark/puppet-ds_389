require 'spec_helper'

describe 'ds_389::ssl' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specdirectory' }

  let(:ssl_default) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: sslVersionMin
sslVersionMin: TLS1.1
-
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off
'
  end

  let(:ssl_no_version_min) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off
'
  end

  let(:ssl_custom) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: sslVersionMin
sslVersionMin: TLS1.2
-
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off
'
  end

  let(:ssl_custom_no_version_min) do
    'dn: cn=encryption,cn=config
changetype: modify
replace: nsSSLClientAuth
nsSSLClientAuth: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsSSL2
nsSSL2: off
'
  end

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
            cert_name: 'foo.example.com',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Import ssl ldif: specdirectory').with(
            command: 'ldapmodify -xH ldap://foo.example.com:389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-specdirectory/ssl.ldif && touch /etc/dirsrv/slapd-specdirectory/ssl.done',
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-specdirectory/ssl.done',
          ).that_requires('File[/etc/dirsrv/slapd-specdirectory/ssl.ldif]').that_notifies(
            'Exec[Restart specdirectory to enable SSL]',
          )
        }
        case os_facts[:kernel]
        when 'Linux'
          it {
            is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/ssl.ldif').with(
              ensure: 'file',
              mode: '0440',
              owner: 'dirsrv',
              group: 'dirsrv',
              content: ssl_default,
            )
          }

          it {
            is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
              command: 'systemctl restart dirsrv@specdirectory ; sleep 2',
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }
        else
          it {
            is_expected.to contain_exec('Restart specdirectory to enable SSL').with(
              command: 'service dirsrv restart specdirectory ; sleep 2',
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }
        end
      end

      context 'with all params' do
        let(:title) { 'ldap01' }
        let(:params) do
          {
            cert_name: 'ldap.test.org',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecure',
            server_host: 'ldap.test.org',
            server_port: 1389,
            server_ssl_port: 1636,
            user: 'custom_user',
            group: 'custom_group',
            minssf: 128,
            ssl_version_min: 'TLS1.2',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_exec('Import ssl ldif: ldap01').with(
            command: 'ldapmodify -xH ldap://ldap.test.org:1389 -D "cn=Directory Manager" -w supersecure -f /etc/dirsrv/slapd-ldap01/ssl.ldif && touch /etc/dirsrv/slapd-ldap01/ssl.done',
            path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
            creates: '/etc/dirsrv/slapd-ldap01/ssl.done',
          ).that_requires('File[/etc/dirsrv/slapd-ldap01/ssl.ldif]').that_notifies(
            'Exec[Restart ldap01 to enable SSL]',
          )
        }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-ldap01/ssl.ldif').with(
            ensure: 'file',
            mode: '0440',
            owner: 'custom_user',
            group: 'custom_group',
            content: ssl_custom,
          )
        }

        case os_facts[:kernel]
        when 'Linux'
          it {
            is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
              command: 'systemctl restart dirsrv@ldap01 ; sleep 2',
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }
        else
          it {
            is_expected.to contain_exec('Restart ldap01 to enable SSL').with(
              command: 'service dirsrv restart ldap01 ; sleep 2',
              path: '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin',
              refreshonly: true,
            )
          }
        end
      end
    end
  end
end
