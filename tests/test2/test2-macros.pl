#!/usr/bin/perl
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 7;

# Definitions

my $macrobuild = 'perl -I../../vendor_perl -I.. -I/usr/lib/perl5/vendor_perl ../../bin/macrobuild --logconfig ../../etc/macrobuild/log-default-v1.conf';
my $out;

# Test Replace 1

is( myexec( "$macrobuild -i Test2.in"
            . " search-replace-with",
            undef, \$out, \$out ), 0, "test2-replace1-a" );

like( $out, qr/Abc/, "test2-replace1-b" );

unlike( $out, qr/Nothing to do/, "test2-replace1-c" );

# Test Replace 2

is( myexec( "$macrobuild -i Test2.in"
            . " search-replace-without pattern=a replacement=AXA",
            undef, \$out, \$out ), 0, "test2-replace2-a" );

like( $out, qr/AXAbc/, "test2-replace2-b" );

# Test Replace 3

is( myexec( "$macrobuild -i Test2.in"
            . " search-replace-without-indirect pattern=a replacement=AXA",
            undef, \$out, \$out ), 0, "test2-replace3-a" );

like( $out, qr/AXAbc/, "test2-replace3-b" );

1;
