#!/usr/bin/perl
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 2;

# Definitions

my $macrobuild = 'perl -I../../vendor_perl -I.. -I/usr/lib/perl5/vendor_perl ../../bin/macrobuild --logconfig ../../etc/macrobuild/log-default-v1.conf';
my $out;

# Test

isnt( myexec( "$macrobuild"
            . " TestTasks::OtherOuter",
            undef, \$out, \$out ), 0, "test7-valuetrace1-a" );

like( $out, qr/replacing var.*THIS_IS_NOT_DEFINED_OtherInner.*tried.*TestTasks::OtherInner.*tried.*TestTasks::OtherOuter.*tried.*Macrobuild::Constants/s, "test7-valuetrace1-b" );
# three tries in the trace

1;
