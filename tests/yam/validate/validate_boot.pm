# SUSE's openQA tests
#
# Copyright 2026 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Validates successful first boot into the installed system
#          by checking the welcome banner on serial console.
#
# Maintainer: QE Installation and Migration (QE Iam) <none@suse.de>
#
#
use Mojo::Base 'consoletest';
use testapi;
use Utils::Architectures qw(is_ppc64le is_aarch64 is_s390x);

sub run {
    my $self = shift;

    my $version = get_var('VERSION');

    my $arch;
    if (is_s390x) {
        $arch = 's390x';
    } elsif (is_ppc64le) {
        $arch = 'ppc64le';
    } elsif (is_aarch64) {
        $arch = 'aarch64';
    } else {
        $arch = 'x86_64';
    }

    my $version_regex = $version;
    $version_regex =~ s/\./\\./g;

    my $regex = qr/Welcome to SUSE Linux Enterprise Server $version_regex.*$arch/;
    record_info('First Boot', "Waiting for OS boot banner on serial console ($arch)...");
    send_key 't';
    type_string "t\n";

    my $match = wait_serial($regex, timeout => 300);
    die "Failed to detect OS first boot welcome banner on serial console for $arch" unless ($match);
    record_info('Boot Success', "System successfully booted into target OS ($arch)");
}

sub test_flags {
    return {fatal => 1};
}

1;
