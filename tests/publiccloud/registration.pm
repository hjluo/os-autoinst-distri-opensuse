# SUSE's openQA tests
#
# Copyright 2019-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: cloud-regionsrv-client
# Summary: Register addons in the remote system
#   Registration is in registercloudguest test module
#
# Maintainer: <qa-c@suse.de>

use Mojo::Base 'publiccloud::basetest';
use version_utils;
use registration;
use warnings;
use testapi;
use strict;
use utils;
use publiccloud::utils;
use publiccloud::ssh_interactive "select_host_console";
use File::Basename 'basename';

sub run {
    my ($self, $args) = @_;

    $self->{instance} = $args->{my_instance};

    select_host_console();    # select console on the host, not the PC instance

    registercloudguest($args->{my_instance}) if (is_byos() || get_var('PUBLIC_CLOUD_FORCE_REGISTRATION'));
    register_addons_in_pc($args->{my_instance});
    # Since SLE 15 SP6 CHOST images don't have curl and we need it for testing
    if (is_sle('>15-SP5') && is_container_host()) {
        $self->{instance}->ssh_assert_script_run('sudo zypper -n in --force-resolution -y curl');
    }
}

sub cleanup {
    my ($self) = @_;
    my @logs = ('/var/log/cloudregister', '/etc/hosts', '/var/log/zypper.log', '/etc/zypp/credentials.d/SCCcredentials');
    $self->{instance}->ssh_script_run("sudo chmod a+r " . join(' ', @logs));
    for my $file (@logs) {
        $self->{instance}->upload_log($file, log_name => $autotest::current_test->{name} . '-' . basename($file) . '.txt');
    }
    if (is_azure()) {
        record_info('azuremetadata', $self->{instance}->run_ssh_command(cmd => "sudo /usr/bin/azuremetadata --api latest --subscriptionId --billingTag --attestedData --signature --xml"));
    }
}

sub test_flags {
    return {fatal => 1, publiccloud_multi_module => 1};
}

1;
