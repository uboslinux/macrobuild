# 
# A build Task that first runs a splitting task, then two or more parallel tasks,
# and then a joining Task. Optionally, we can specify a specify a sequence in
# which the parallel tasks should be processed.
#
# Note: parallel here means parallel with respect to the data flow, not in
# terms of execution.
#
# This file is part of macrobuild.
# (C) 2014-2017 Indie Computing Corp.
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
use fields qw( splitTask parallelTasks parallelTasksSequence joinTask );

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
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $ret      = 0;
    my $continue = 1;

    my $previousChildRun = undef;

    my $splitTask = $self->{splitTask};
    if( $splitTask ) {
        $previousChildRun = $run->createChildRun( $splitTask );
        my $taskRet       = $splitTask->run( $previousChildRun );

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
    }

    if( $continue ) {
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

        my $outData = {};

        foreach my $taskName ( @realSequence ) {
            my $task = $self->{parallelTasks}->{$taskName};

            my $childRun = $run->createChildRun( $task, $previousChildRun );
            my $taskRet  = $task->run( $childRun );

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

        # we create a "disattached" $previousChildRun that carries the aggregated $outData
        # as its output
        $previousChildRun = Macrobuild::TaskRun->new( {}, $run, $self );
        $previousChildRun->setOutput( $outData );
    }
    if( $continue ) {
        my $joinTask = $self->{joinTask};
        if( $joinTask ) {
            $previousChildRun = $run->createChildRun( $joinTask, $previousChildRun );
        
            my $taskRet = $joinTask->run( $previousChildRun );

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
        }
    }
    $run->setOutput( $previousChildRun->getOutput() );

    return $ret;
}

1;
