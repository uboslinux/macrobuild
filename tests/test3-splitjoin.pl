#!/usr/bin/perl

use strict;
use warnings;

use UBOS::Utils;
use Test::More tests => 6;

# Definitions

my $macrobuild = 'perl -I../vendor_perl -I. -I/usr/lib/perl5/vendor_perl ../bin/macrobuild -v -v';
my $out;
my $err;

# Test Replace 1

is( myexec( "$macrobuild -i Test3.in"
            . " TestTasks::SearchReplaceDifferently",
            undef, \$out, \$err ), 0, "test3-replace1-a" );

unlike( $out, qr/Nothing to do/, "test3-replace1-b" );

my $json = UBOS::Utils::readJsonFromString( $out );

cmp_ok( $json->{'1bc'},           'eq', 'def', "test4-replace1-c1" );
ok(     !exists( $json->{'2bc'}),              "test4-replace1-c2" );
cmp_ok( $json->{'3bc'},           'eq', 'def', "test4-replace1-c3" );
cmp_ok( scalar( @{$json->{ghi}}), '==', 6,     "test4-replace1-c4" );

1;
 
