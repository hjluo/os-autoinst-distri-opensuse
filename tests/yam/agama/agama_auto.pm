## Copyright 2024 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Wait for unattended installation to finish,
# reboot and reach login prompt.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base Yam::Agama::agama_base;
use strict;
use warnings;

use testapi;
use Utils::Backends qw(is_hyperv);
use power_action_utils 'power_action';
use version_utils qw(is_leap);

sub run {
    select_console 'root-console';

    my $self = shift;

    my $timeout = 30 * 60;
    my $check_interval = 30;
    my $auto_success = 0;
    my $install_success = 0;

    # Start time
    my $start_time = time();
    my $end_time = $start_time + $timeout;

    diag("Starting to monitor Agama installation logs...");
    while (time() < $end_time) {
        if (!$auto_success) {
            my $auto_output = script_output('journalctl -u agama-auto --no-pager -n 5');
            if ($auto_output =~ /agama-auto\.service: Deactivated successfully/) {
                $auto_success = 1;
                record_info("journalctl", "Found 'agama-auto.service: Deactivated successfully'");
            }
        }
        if (!$install_success) {
            my $install_output = script_output('journalctl -u agama --no-pager -n 5');
            if ($install_output =~ /\[INFO\]: manager: Finished the installation \(stop\)\./) {
                $install_success = 1;
                record_info("journalctl", "Found 'manager: Finished the installation'");
            }
        }

        if ($auto_success && $install_success) {
            my $elapsed = time() - $start_time;
            record_info("Install finished", "Installation completed successfully after $elapsed seconds!");
            last;
        }
        sleep($check_interval);
    }

    die "Installation didn't complete within the expected time frame." if (!$auto_success || !$install_success);

    if (!is_leap()) {
        # While the work on Agama settles, on leap
        # Leave log collection for the post_fail_hook
        # see also https://progress.opensuse.org/issues/182102
        $self->upload_agama_logs() unless is_hyperv();
    }

    power_action('reboot', keepconsole => 1, first_reboot => 1);
}

1;
