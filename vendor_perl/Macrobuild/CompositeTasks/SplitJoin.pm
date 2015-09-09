# 
# A build Task that first runs a splitting task, then two or more parallel tasks,
# and then a joining Task. Optionally, we can specify a specify a sequence in
# which the parallel tasks should be processed.
#
# Note: parallel here means parallel with respect to the data flow, not in
# terms of execution
#
# This file is part of macrobuild.
# (C) 2014-2015 Indie Computing Corp.
#
# macrobuild is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# macrobuild is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with macrobuild.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

package Macrobuild::CompositeTasks::SplitJoin;

use base qw( Macrobuild::Task );
use fields qw( splitTask splitParallelTaskInputs parallelTasks parallelTasksSequence joinTask );

use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my %args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{showInLog} = 0;
    
    $self->SUPER::new( %args );
    
    return $self;
}

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;

    my $ret      = 0;
    my $continue = 1;

    my $in       = $run->taskStarting( $self );
    my $nextIn   = $in;

    my $splitTask = $self->{splitTask};
    if( $splitTask ) {
        my $childRun = $run->createChildRun( $in );
        my $taskRet  = $splitTask->run( $childRun );

        if( $taskRet ) {
            if( $taskRet < 0 ) {
                $ret = $taskRet;
                if( $self->{stopOnError} ) {
                    error( "ERROR when executing " . $run->replaceVariables( $splitTask->name()) . ". Stopping." );
                    $continue = 0;
                }
            } else { # >0
                if( $ret == 0 ) { # first one
                    $ret = $taskRet;
                }
            }
        }
        $nextIn = $childRun->getOutput();
    }

    if( $continue ) {
        my $outData = {};

        # determine, check and clean up tasks sequence
        my %inSequence   = ();
        my @realSequence = ();
        if( defined( $self->{parallelTasksSequence} )) {
            foreach my $task ( @{$self->{parallelTasksSequence}} ) {
                if( !exists( $self->{parallelTasks}->{$task} )) {
                    warning( 'Task', $task, 'specified in parallelTasksSequence does not exist in parallelTasks. Ignoring.' );
                } elsif( defined( $inSequence{$task} )) {
                    warning( 'Task', $task, 'specified more than once in parallelTasksSequence. Ignoring second occurrence.' );
                } else {
                    $inSequence{$task} = $task;
                    push @realSequence, $task;
                }
            }
        }
        # put in the remaining tasks in a predictable sequence
        map { my $t = $_; unless( exists( $inSequence{$t} )) { push @realSequence, $t; } } sort keys %{$self->{parallelTasks}};

        foreach my $taskName ( @realSequence ) {
			my $task = $self->{parallelTasks}->{$taskName};

            my $childRun = $run->createChildRun( $self->{splitParallelTaskInputs} ? $nextIn->{$taskName} : $nextIn );

            my $taskRet = $task->run( $childRun );

            if( $taskRet ) {
                if( $taskRet < 0 ) {
                    $ret = $taskRet;
                    if( $self->{stopOnError} ) {
                        error( "ERROR when executing " . $run->replaceVariables( $task->name()) . ". Stopping." );
                        $continue = 0;
                        last;
                    }
                } else { # >0
                    if( $ret == 0 ) { # first one
                        $ret = $taskRet;
                    }
                }
            }
            $outData->{$taskName} = $childRun->getOutput();
        }

        $nextIn = $outData;
    }
    if( $continue ) {
        my $joinTask = $self->{joinTask};
        if( $joinTask ) {
            my $childRun = $run->createChildRun( $nextIn );
        
            my $taskRet = $joinTask->run( $childRun );

            if( $taskRet ) {
                if( $taskRet < 0 ) {
                    $ret = $taskRet;
                    if( $self->{stopOnError} ) {
                        error( "ERROR when executing " . $run->replaceVariables( $joinTask->name()) . ". Stopping." );
                        $continue = 0;
                    }
                } else { # >0
                    if( $ret == 0 ) { # first one
                        $ret = $taskRet;
                    }
                }
            }
            $nextIn = $childRun->getOutput();
        }
    }

    $run->taskEnded( $self, $nextIn, $ret );

    return $ret;
}

1;
