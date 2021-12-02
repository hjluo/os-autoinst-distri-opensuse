# SLE12 online migration tests
#
# Copyright 2016-2018 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: zypper
# Summary: Fully patch the system before conducting an online migration
# Maintainer: yutao <yuwang@suse.com>

use base "consoletest";
use strict;
use warnings;
use testapi;
use utils;
use power_action_utils 'power_action';
use version_utils qw(is_desktop_installed is_sles4sap);
use migration;
use qam;
use Utils::Backends 'is_pvm';

sub run {
    my ($self) = @_;
    select_console 'root-console';

    script_run("df -Th");
    disable_installation_repos;
    add_test_repositories;
    fully_patch_system;
    install_patterns() if (get_var('PATTERNS'));
    deregister_dropped_modules;
    cleanup_disk_space if get_var('REMOVE_SNAPSHOTS');
    power_action('reboot', keepconsole => 1, textmode => 1);
    reconnect_mgmt_console if is_pvm;

    # Do not attempt to log into the desktop of a system installed with SLES4SAP
    # being prepared for upgrade, as it does not have an unprivileged user to test
    # with other than the SAP Administrator
    $self->wait_boot(textmode => !is_desktop_installed, bootloader_time => 300, ready_time => 600, nologin => is_sles4sap);
    $self->setup_migration;
}

sub test_flags {
    return {fatal => 1};
}

1;
