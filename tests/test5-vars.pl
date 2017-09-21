#!/usr/bin/perl

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 12;

# Definitions

my $macrobuild = 'perl -I../vendor_perl -I. -I/usr/lib/perl5/vendor_perl ../bin/macrobuild -v';
my $out;

# Test parameters provided directly to task

is( myexec( $macrobuild
            . " Macrobuild::BasicTasks::Hello message=direct",
            undef, \$out, \$out ), 0, "test5-vars1-a" );

like( $out, qr/direct/, "test5-vars1-b" );
unlike( $out, qr/shared/, "test5-test1-c" );

# Test shared parameters

is( myexec( $macrobuild
            . " message=shared Macrobuild::BasicTasks::Hello",
            undef, \$out, \$out ), 0, "test5-vars2-a" );

like( $out, qr/shared/, "test5-vars2-b" );
unlike( $out, qr/direct/, "test5-test2-c" );

# Test direct parameter overrides shared

is( myexec( $macrobuild
            . " message=shared Macrobuild::BasicTasks::Hello message=direct",
            undef, \$out, \$out ), 0, "test5-vars3-a" );

like( $out, qr/direct/, "test5-vars3-b" );
unlike( $out, qr/shared/, "test5-test3-c" );

# Test both can work together

is( myexec( $macrobuild
            . " message=shared"
            . "     Macrobuild::BasicTasks::Hello message=direct"
            . "     Macrobuild::BasicTasks::Hello",
            undef, \$out, \$out ), 0, "test5-vars4-a" );

like( $out, qr/direct.*shared/s, "test5-vars4-b" );
unlike( $out, qr/shared.*direct/s, "test5-test4-c" );

1;
