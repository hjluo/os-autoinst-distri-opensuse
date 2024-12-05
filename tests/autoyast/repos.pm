# Copyright 2015-2021 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Package: iproute2 systemd PackageKit zypper yast2 tar bzip2
# Summary: Verify network and repos are available
# - Check status of all network interfaces
# - Stop packagekit service
# - Enable install DVD
# - Install yast2 tar bzip2
# - Save yast2 logs
# Maintainer: Pavel Sladek <psladek@suse.cz>

use strict;
use warnings;
use base 'y2_module_consoletest';
use testapi;
use utils;
use zypper;

sub run {
    # sles12_minimal.xml profile does not install "ip"
    assert_script_run 'ip a || ifstatus all';
    if (!check_var('DESKTOP', 'textmode')) {
        quit_packagekit;
        # poo#87850 wait the zypper processes in background to finish and release the lock.
        wait_quit_zypper;
    }
    zypper_enable_install_dvd;
    # make sure that save_y2logs from yast2 package, tar and bzip2 are installed
    # even on minimal system
    record_info('Installed patterns', script_output('zypper pt -i', proceed_on_failure => 1));
    record_info('All patterns', script_output('zypper pt -u', proceed_on_failure => 1));

    zypper_call 'in yast2 tar bzip2';
    assert_script_run 'save_y2logs /tmp/y2logs.tar.bz2';
    upload_logs '/tmp/y2logs.tar.bz2';
}

1;

