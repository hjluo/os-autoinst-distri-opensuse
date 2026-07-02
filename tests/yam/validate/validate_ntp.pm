# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Validate the ntp servers and chronyc tracking by checking
# - NTP servers are present in /etc/chrony.d/99-installer.conf
# - No Pending Leap Seconds are detected via chronyc tracking.

# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use Mojo::Base 'consoletest';
use testapi;
use scheduler qw(get_test_suite_data);
use utils qw(systemctl);

sub run {
    my $test_data = get_test_suite_data();
    select_console 'root-console';

    my $chrony_config = '/etc/chrony.d/99-installer.conf';
    systemctl('status chronyd');
    assert_script_run("cat $chrony_config");
    assert_script_run("grep '$_' $chrony_config") foreach @{$test_data->{ntp_servers}};
    my $tracking_output = script_output('chronyc tracking');
    if ($tracking_output =~ /Leap\s+status\s*:\s*(?<status>.+?)\s*$/m) {
        my $status = $+{status};
        $status =~ s/\s+$//;
        if ($status ne 'Normal') {
            assert_script_run('chronyc makestep');
            my $fresh_output = script_output("chronyc tracking");
            if ($fresh_output =~ /Leap\s+status\s*:\s*(?<new_status>.+?)\s*$/m) {
                $status = $+{new_status};
                $status =~ s/\s+$//;
            } else {
                die "Could not parse Leap status during validation check.";
            }
        }
        die "Chrony tracking failed. Expected Leap status 'Normal', but got '$status'." if $status ne 'Normal';
    } else {
        die "Could not parse Leap status from chronyc tracking output.";
    }

}

1;
