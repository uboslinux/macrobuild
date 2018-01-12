#!/usr/bin/perl
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 13;

# Definitions

my $macrobuild = 'perl -I../../vendor_perl -I.. -I/usr/lib/perl5/vendor_perl ../../bin/macrobuild --logconfig ../../etc/macrobuild/log-default-v1.conf';
my $out;

my @tests = (
    undef, # control test -- no error
    qr/aborting with error/i,
    qr/sequential child task.*aborting with error/si,
    qr/split task.*aborting with error/si,
    qr/join task.*aborting with error/si,
    qr/parallel task.*aborting with error/si,
    qr/no delegate.*aborting with error/si
);

for( my $i=0 ; $i<@tests ; ++$i ) {
    my $ret = myexec( "$macrobuild"
            . " TestTasks::OuterFail par=$i",
            undef, \$out, \$out );
    if( $i ) {
        isnt( $ret, 0, "test8-fail$i-a" );
        like( $out, $tests[$i], "test8-fail$i-b" );
    } else {
        is( $ret, 0, "test8-fail$i-a" );
    }
}

1;
