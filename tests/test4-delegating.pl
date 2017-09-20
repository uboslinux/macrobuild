#!/usr/bin/perl

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 3;

# Definitions

my $macrobuild = 'perl -I../vendor_perl -I. -I/usr/lib/perl5/vendor_perl ../bin/macrobuild -v';
my $out;

# Test Replace 1

is( myexec( "$macrobuild -i Test4.in"
            . " DelegatingSearchReplaceTestPattern=aa TestTasks::DelegatingSearchReplace",
            undef, \$out, \$out ), 0, "test4-replace1-a" );

like( $out, qr/aaaXccc/, "test4-replace1-b" );

unlike( $out, qr/Nothing to do/, "test4-replace1-c" );

1;
