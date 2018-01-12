#
# Looks for a certain pattern in the input, and replaces it with another
# in the output.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package TestTasks::SearchReplace;

use Storable qw(dclone);
use UBOS::Logging;

use base qw( Macrobuild::Task );
use fields qw( pattern replacement );

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $count = 0;
    my $out = $self->_replace( $run->getInput, $run, \$count );

    $run->setOutput( $out );

    if( $count ) {
        return $self->SUCCESS;
    } else {
        return $self->DONE_NOTHING;
    }
}

sub _replace {
    my $self   = shift;
    my $in     = shift;
    my $run    = shift;
    my $countP = shift;

    my $pattern     = $self->getProperty( 'pattern' );
    my $replacement = $self->getProperty( 'replacement' );

    my $type = ref( $in );
    my $ret;
    if( $type eq 'ARRAY' ) {
        $ret = [];
        for my $e ( @$in ) {
            push @$ret, $self->_replace( $e, $run, $countP );
        }
    } elsif( $type eq 'HASH' ) {
        $ret = {};
        for my $key ( keys %$in ) {
            $ret->{$self->_replace( $key, $run, $countP )} = $self->_replace( $in->{$key}, $run, $countP );
        }
    } else {
        $ret = $in;
        $$countP += ( $ret =~ s!$pattern!$replacement!g );
    }
    return $ret;
}

1;

