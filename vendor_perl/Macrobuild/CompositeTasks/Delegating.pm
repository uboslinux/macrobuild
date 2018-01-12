#
# Delegates to another task which a subclass needs to define
# in the constructor.
#
# Copyright (C) 2014 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::CompositeTasks::Delegating;

use base qw( Macrobuild::Task );
use fields qw( _delegate );

use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->SUPER::new( @args );

    $self->{showInLog} = 0;

    return $self;
}

##
# @Overridden
sub getName {
    my $self = shift;

    my $ret = $self->SUPER::getName();
    unless( $ret ) {
        if( ref( $self ) eq 'Macrobuild::CompositeTasks::Delegating' ) {
            $ret = 'Delegating to ' . $self->{_delegate};
        }
    }
    return $ret;
}

##
# Set the delegate task
# $task: the task to set
sub setDelegate {
    my $self = shift;
    my $task = shift;

    if( exists( $self->{_delegate} )) {
        warning( 'Delegating: delegate task was previously set, overriding' );
    }
    $self->{_delegate} = $task;
}

##
# @Overridden
sub getSubtasks {
    my $self = shift;

    if( defined( $self->{_delegate} )) {
        return ( $self->{_delegate} );
    } else {
        return ();
    }
}

##
# @Overridden
sub runImpl {
    my $self = shift;
    my $run  = shift;

    if( defined( $self->{_delegate} )) {
        my $childRun = $run->createChildRun( $self->{_delegate} );

        my $ret = $self->{_delegate}->run( $childRun );

        unless( $ret ) {
            $run->setOutput( $childRun->getOutput() );
        }
        return $ret;

    } else {
        error( "No delegate defined for delegating task", $self );
        return $self->FAIL;
    }
}

1;
