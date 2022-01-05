# SUSE's openQA tests
#
# Copyright 2021 SUSE LLC
# SPDX-License-Identifier: FSFAP
# Summary: Package for ssh service tests
#
# Maintainer: QE YaST <qa-sle-yast@suse.de>

package services::sshd;
use base 'opensusebasetest';
use testapi;
use utils;
use strict;
use warnings;

sub check_sshd_port {
    assert_script_run q(ss -pnl4 | egrep 'tcp.*LISTEN.*:22.*sshd');
    assert_script_run q(ss -pnl6 | egrep 'tcp.*LISTEN.*:22.*sshd');
}

sub check_sshd_service {
    systemctl 'show -p ActiveState sshd|grep ActiveState=active';
    systemctl 'show -p SubState sshd|grep SubState=running';
}

sub configure_service {
    # Backup/rename ~/.ssh , generated in consotest_setup, to ~/.ssh_bck
    assert_script_run 'if [ -d ~/.ssh ]; then mv ~/.ssh ~/.ssh_bck; fi';

    # prepare /etc/ssh configuration for openssh with default config in /usr/etc
    script_run 'test -f /usr/etc/ssh/sshd_config -a ! -f /etc/ssh/sshd_config && cp /usr/etc/ssh/sshd_config /etc/ssh/sshd_config';

    # Backup the /etc/ssh/sshd_config
    assert_script_run 'cp /etc/ssh/sshd_config{,_before}';

    # new user to test sshd
    my $ssh_testman = "sshboy";
    my $ssh_testman_passwd = get_var('PUBLIC_CLOUD') ? random_string(8) : 'let3me2in1';

    # Allow password authentication for $ssh_testman
    assert_script_run(qq(echo -e "Match User $ssh_testman\\n\\tPasswordAuthentication yes" >> /etc/ssh/sshd_config)) if (get_var('PUBLIC_CLOUD'));

    # Install software needed for this test module
    zypper_call("in netcat-openbsd expect psmisc");

    if (script_run('systemctl is-active firewalld') == 0) {
        systemctl('stop firewalld');
    }
}

sub check_service {
    systemctl 'is-enabled sshd.service';
    systemctl 'is-active sshd';
}
sub check_function {
    my $ssh_testman = "sshboy";
    my $ssh_testman_passwd = get_var('PUBLIC_CLOUD') ? random_string(8) : 'let3me2in1';

    # Check that the daemons listens on right addresses/ports
    check_sshd_port();

    # create a new user to test sshd
    my $changepwd = $ssh_testman . ":" . $ssh_testman_passwd;
    assert_script_run("useradd -m $ssh_testman");
    assert_script_run("echo $changepwd | chpasswd");
    assert_script_run("usermod -aG \$(stat -c %G /dev/$serialdev) $ssh_testman");

    # avoid harmless failures in virtio-console due to unexpected PS1
    assert_script_run("echo \"PS1='# '\" >> ~$ssh_testman/.bashrc") unless check_var('VIRTIO_CONSOLE', '0');

    # Make interactive SSH connection as the new user
    enter_cmd "expect -c 'spawn ssh $ssh_testman\@localhost -t;expect \"Are you sure\";send yes\\n;expect sword:;send $ssh_testman_passwd\\n;expect #;send \\n;interact'";
    sleep(1);

    # Check that we are really in the SSH session
    assert_script_run 'echo $SSH_TTY | grep "\/dev\/pts\/"';
    assert_script_run 'ps ux | egrep ".* \? .* sshd\:"';
    assert_script_run "whoami | grep $ssh_testman";
    assert_script_run "mkdir .ssh";

    # Exit properly and check we're root again
    script_run("exit", 0);
    assert_script_run "whoami | grep root";

    # Generate RSA key for root and the user
    assert_script_run "ssh-keygen -t rsa -P '' -C 'root\@localhost' -f ~/.ssh/id_rsa";
    assert_script_run "su -c \"ssh-keygen -t rsa -P '' -C '$ssh_testman\@localhost' -f /home/$ssh_testman/.ssh/id_rsa\" $ssh_testman";

    # Make sure user has both public keys in authorized_keys
    assert_script_run "su -c \"cp /home/$ssh_testman/.ssh/{id_rsa.pub,authorized_keys}\"";
    assert_script_run "cat ~/.ssh/id_rsa.pub >> /home/$ssh_testman/.ssh/authorized_keys";

    # Test non-interactive SSH
    assert_script_run "ssh -4v $ssh_testman\@localhost bash -c 'whoami | grep $ssh_testman'";

    # Connect to forwarded ports
    assert_script_run "ssh -v -p 4242 $ssh_testman\@localhost whoami";
    assert_script_run "ssh -v -p 5252 $ssh_testman\@localhost whoami";

    # Copy the list of known hosts to $ssh_testman's .ssh directory
    assert_script_run "install -m 0400 -o $ssh_testman ~/.ssh/known_hosts /home/$ssh_testman/.ssh/known_hosts";

    # Test SSH command within SSH command
    assert_script_run "ssh -v -p 4242 -tt $ssh_testman\@localhost ssh -tt $ssh_testman\@localhost whoami";

    # Test ProxyCommand option
    assert_script_run "ssh -v -t -o ProxyCommand='ssh -v $ssh_testman\@localhost nc localhost 4242' $ssh_testman\@localhost whoami";

    # Test JumpHost option
    if (is_leap('15.0+') || is_tumbleweed || is_sle('15+')) {
        assert_script_run("ssh -v -J $ssh_testman\@localhost:4242 $ssh_testman\@localhost whoami");
    }

    # SCP (poo#46937)
    assert_script_run "echo 'sshd.pm: Testing SCP subsystem' | logger";
    assert_script_run "scp -4v $ssh_testman\@localhost:/etc/resolv.conf /tmp";
    assert_script_run "scp -4v '$ssh_testman\@localhost:/etc/{group,passwd}' /tmp";
    assert_script_run "scp -4v '$ssh_testman\@localhost:/etc/ssh/*.pub' /tmp";
}

# check sshd service before and after migration
# stage is 'before' or 'after' system migration.
sub full_sshd_check {
    my (%hash) = @_;
    my $stage = $hash{stage};
    configure_service();
    check_service();
    check_function();
}

# Cleanup for exceptions during before and after migration
sub sshd_cleanup {
    my (%hash) = @_;
    my $stage = $hash{stage};

    select_console "root-console";

    assert_script_run 'rm -rf ~/.ssh';
    assert_script_run 'if [ -d ~/.ssh_bck ]; then mv ~/.ssh_bck ~/.ssh; fi';

    # Restore the /etc/ssh/sshd_config
    assert_script_run 'cp /etc/ssh/sshd_config{_before,}';

    # Kill $ssh_testman to stop all SSH sessions
    assert_script_run "killall -u $ssh_testman || true";
    wait_still_screen 3;

    record_info("Restart sshd", "Restart sshd.service");
    systemctl("restart sshd");

    # Clear the remains from background commands
    clear_console if !is_serial_terminal;
}

1;
