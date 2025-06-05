# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP
#
# Summary: Validate the base product from /etc/products.d/baseproduct.
# Maintainer: QE YaST and Migration (QE Yam) <qe-yam at suse de>

use base "consoletest";
use strict;
use warnings;
use testapi;
use Test::Assert ':assert';

sub run {
    select_console 'root-console';
    script_run('zypper in SUSEConnet');
    script_run("zypper rr \$(zypper lr -u | awk 'NR>2 {print \$1}')");
    script_run('SUSEConnet -d');
    script_run('SUSEConnet --cleanup');
    script_run('SUSEConnet -p SLES/16.0/x86_64 --url http://migration-rmt2.qe.nue2.suse.org');
    script_run('zypper lr -u');
    my $expected_prod = get_required_var("AGAMA_PRODUCT_ID");
    my $prod = script_output 'basename `readlink /etc/products.d/baseproduct ` .prod';
    assert_equals($expected_prod, $prod, "Wrong product name in '/etc/products.d/baseproduct'");
}

1;
