## Copyright 2024 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Run Agama profile import on Live Medium
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base Yam::Agama::patch_agama_base;
use strict;
use warnings;
use testapi qw(assert_script_run data_url get_required_var select_console script_run);

sub run {
    select_console 'root-console';
    my $profile = get_required_var('AGAMA_PROFILE');
    my $profile_url = data_url($profile);
    script_run("dmesg --console-off");
    assert_script_run("/usr/bin/agama profile import $profile_url", timeout => 300);
    script_run("dmesg --console-on");
}

1;