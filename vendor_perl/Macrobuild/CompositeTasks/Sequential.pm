#
# A build Task that performs a number of other Tasks in sequence.
#
# Copyright (C) 2014 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::CompositeTasks::Sequential;

use base qw( Macrobuild::Task );
use fields qw( _tasks );

use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{showInLog} = 0;
    $self->{name}      = ref( $self );
    $self->{_tasks}    = [];

    $self->SUPER::new( @args );

    return $self;
}

##
# Append a task
# $task: the task to add
sub appendTask {
    my $self = shift;
    my $task = shift;

    push @{$self->{_tasks}}, $task;
}

##
# @Overridden
sub getSubtasks {
    my $self = shift;

    return @{$self->{_tasks}};
}

##
# @Overridden
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $previousChildRun = undef;
    my $ret = 0;
    foreach my $childTask ( @{$self->{_tasks}} ) {

        my $childRun = $run->createChildRun( $childTask, $previousChildRun );

        my $childTaskRet = $childTask->run( $childRun );

        $previousChildRun = $childRun;

        if( $childTaskRet ) {
            if( $childTaskRet < 0 ) {
                $ret = $childTaskRet;
                if( $self->{stopOnError} ) {
                    error( 'During execution of sequential child task and stopping:', $childTask );
                    last;
                }
            } else { # >0
                if( $ret == 0 ) { # first one
                    $ret = $childTaskRet;
                }
            }
        }
    }
    if( $previousChildRun ) {
        $run->setOutput( $previousChildRun->getOutput() );
    }

    return $ret;
}

1;
