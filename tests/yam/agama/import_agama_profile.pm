## Copyright 2024 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Run Agama profile import on Live Medium
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base Yam::Agama::patch_agama_base;
use strict;
use warnings;
use testapi qw(assert_script_run data_url get_var record_info select_console script_run);
use autoyast qw(expand_agama_profile);

sub run {
    unless (get_var('AGAMA_PROFILE')) {
        record_info('import_agama_profile', 'nothing to do');
        return;
    }
    my $profile = expand_agama_profile(get_var('AGAMA_PROFILE'));
    select_console 'root-console';
    script_run("dmesg --console-off");
    assert_script_run("agama profile import $profile", timeout => 300);
    script_run("dmesg --console-on");
}

1;
