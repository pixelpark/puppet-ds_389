require 'spec_helper'

describe 'ds_389::backup' do
  let(:pre_condition) { 'class {"ds_389": }' }
  let(:title) { 'specbackup' }

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
          is_expected.to contain_file('/var/lib/dirsrv/slapd-specdirectory/bak').with(
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/backup_passwd.specbackup').with(
            ensure: 'present',
          )
        }

        it {
          is_expected.to contain_cron('Backup job for specdirectory: specbackup').with(
            command: "dsconf -D 'cn=Directory Manager' -y '/etc/dirsrv/slapd-specdirectory/backup_passwd.specbackup' ldaps://foo.example.com:636 backup create  && touch /tmp/389ds_backup_success && find '/var/lib/dirsrv/slapd-specdirectory/bak/' -mindepth 1 -maxdepth 1 -mtime +30 -print0 | xargs -0 -r rm -rf", # rubocop:disable LineLength
            environment: ["PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"],
            user: 'dirsrv',
            minute: '15',
            hour: '23',
            weekday: '*',
          )
        }
      end

      context 'when disabling a backup job' do
        let(:params) do
          {
            ensure: 'absent',
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/var/lib/dirsrv/slapd-specdirectory/bak').with(
            # should NOT be removed
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/backup_passwd.specbackup').with(
            ensure: 'absent',
          )
        }

        it {
          is_expected.to contain_cron('Backup job for specdirectory: specbackup').with(
            ensure: 'absent',
            user: 'dirsrv',
            minute: '15',
            hour: '23',
            weekday: '*',
          )
        }
      end

      context 'with all params' do
        let(:params) do
          {
            ensure: 'present',
            server_id: 'specdirectory',
            root_dn: 'cn=Directory Manager',
            root_dn_pass: 'supersecret',
            backup_dir: '/path/to/ds-backups',
            environment: ['MAILTO=admin@example.com'],
            protocol: 'ldap',
            rotate: 10,
            server_host: 'ldap.test.org',
            server_port: 1389,
            success_file: '/tmp/hourly_backup_success',
            time: ['0', '*', '*'],
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_file('/path/to/ds-backups').with(
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file('/etc/dirsrv/slapd-specdirectory/backup_passwd.specbackup').with(
            ensure: 'present',
          )
        }

        it {
          is_expected.to contain_cron('Backup job for specdirectory: specbackup').with(
            command: "dsconf -D 'cn=Directory Manager' -y '/etc/dirsrv/slapd-specdirectory/backup_passwd.specbackup' ldap://ldap.test.org:1389 backup create /path/to/ds-backups && touch /tmp/hourly_backup_success && find '/path/to/ds-backups/' -mindepth 1 -maxdepth 1 -mtime +10 -print0 | xargs -0 -r rm -rf", # rubocop:disable LineLength
            environment: ["MAILTO=admin@example.com","PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"],
            user: 'dirsrv',
            minute: '0',
            hour: '*',
            weekday: '*',
          )
        }
      end
    end
  end
end
