#!/usr/bin/perl

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 10;

# Definitions

my $macrobuild = 'perl -I../../vendor_perl -I.. -I/usr/lib/perl5/vendor_perl ../../bin/macrobuild -v';
my $out;

# Test Replace 1

is( myexec( "$macrobuild -i Test1.in"
            . " TestTasks::SearchReplace pattern=a replacement=A",
            undef, \$out, \$out ), 0, "test1-replace1-a" );

like( $out, qr/Abc/, "test1-replace1-b" );

unlike( $out, qr/Nothing to do/, "test1-replace1-c" );

# Test Replace 2

is( myexec( "$macrobuild -i Test1.in"
            . " TestTasks::SearchReplace pattern=A replacement=XXX",
            undef, \$out, \$out ), 0, "test1-replace2-a" );

unlike( $out, qr/Abc/, "test1-replace2-b" );

like( $out, qr/Nothing to do/, "test1-replace2-c" );

# Test Replace 3

is( myexec( "$macrobuild -i Test1.in"
            . " TestTasks::SearchReplace pattern=a replacement=A"
            . " TestTasks::SearchReplace pattern=A replacement=XXX",
            undef, \$out, \$out ), 0, "test1-replace3-a" );

like( $out, qr/XXXbc/, "test1-replace3-b" );
unlike( $out, qr/Abc/, "test1-replace3-c" );

unlike( $out, qr/Nothing to do/, "test1-replace3-d" );


1;
