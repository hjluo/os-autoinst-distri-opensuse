## Copyright 2024 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Patch Agama on Live Medium using agama download.
# integration test from GitHub.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base Yam::Agama::patch_agama_base;
use testapi qw(assert_script_run select_console);

sub run {
    select_console 'install-shell';

    my $release_url = "https://github.com/jknphy/agama-integration-test-webpack/releases/latest/download/dist.tar.gz";
    assert_script_run("agama download '$release_url' /tmp/dist.tar.gz");
    assert_script_run("mkdir -p /usr/share/agama/system-tests");
    assert_script_run("tar -xzf /tmp/dist.tar.gz -C /usr/share/agama/system-tests --strip-components=1");
}

1;
