## Copyright 2024 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Run Agama profile import on Live Medium
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>

use Mojo::Base 'Yam::Agama::patch_agama_base';
use testapi;
use autoyast qw(expand_agama_profile generate_json_profile);
use version_utils qw(is_sle);

sub run {
    my $profile = get_required_var('AGAMA_PROFILE');
    my $profile_url = ($profile =~ /\.libsonnet/) ?
      generate_json_profile($profile) :
      expand_agama_profile($profile);
    set_var('AGAMA_PROFILE', $profile_url);

    select_console 'install-shell';
    script_run("agama config load $profile_url", 0);
    sleep 10;
    type_string("\t", lf => 0);
    sleep 5;
    type_string("\n", lf => 0);
    wait_serial("OA:DONE-.*-0-OA", timeout => 300) || die "Agama config load failed";
    record_info("Agama configure", script_output('agama config show'));
}

1;
