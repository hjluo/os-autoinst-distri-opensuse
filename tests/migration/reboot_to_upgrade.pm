# SUSE's openQA tests
#
# Copyright © 2018-2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Summary: Reboot machine to perform upgrade
#       Just trigger reboot action, afterwards tests will be
#       incepted by later test modules, such as tests in
#       load_boot_tests or wait_boot in setup_zdup.pm
# Maintainer: Wei Gao <wegao@suse.com>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;
use power_action_utils qw(prepare_system_shutdown power_action);
use Utils::Backends 'is_pvm';

sub run {
    my ($self) = @_;

    select_console 'root-console';

    # Mark the hdd has been patched
    set_var('PATCHED_SYSTEM', 1) if get_var('PATCH');

    # Reboot from Installer media for upgrade
    # Aarch64 need BOOT_HDD_IMAGE=1 to keep the correct flow to boot from disk for x11/reboot_gnome.
    if (get_var('UPGRADE') || get_var('AUTOUPGRADE')) {
        set_var('BOOT_HDD_IMAGE', 0) unless check_var('ARCH', 'aarch64');
    }
    assert_script_run "sync", 300;
    if (is_pvm()) {
        diag 'Called power_action reboot textmode=1 ....';
        type_string "reboot\n";
        save_screenshot;
        power_action('reboot', observe => 1, keepconsole => 1, first_reboot => 1);
        #prepare_system_shutdown;
        save_screenshot;
        reconnect_mgmt_console(timeout => 500);
    }
    else {
        type_string "reboot\n";
    }
    # After remove -f for reboot, we need wait more time for boot menu and avoid exception during reboot caused delay to boot up.
    assert_screen('inst-bootmenu', 300) unless check_var('ARCH', 's390x');
}

1;

