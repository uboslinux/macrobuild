#!/usr/bin/perl

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 2;

# Definitions

my $macrobuild = 'perl -I../vendor_perl -I. -I/usr/lib/perl5/vendor_perl ../bin/macrobuild -v';
my $out;

# Test

is( myexec( "$macrobuild"
            . " message=shared TestTasks::Outer message=specific",
            undef, \$out, \$out ), 0, "test6-vars1-a" );

like( $out, qr/specific-outer-inner/, "test6-vars1-b" );

1;
