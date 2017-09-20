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
    $self->{name}      = ref( $self );

    return $self;
}

##
# Set the split task
# $task: the task to set
sub setSplitTask {
    my $self     = shift;
    my $task     = shift;

    unless( $task ) {
        error( 'SplitJoin: will not add undef split task' );
        return;
    }
    if( exists( $self->{splitTask} )) {
        warning( 'SplitJoin: split task was previously set, overriding' );
    }
    $self->{splitTask} = $task;
}

##
# Add a parallel task
# $taskName identifier of the task to add, local to this task
# $task: the task to add
sub addParallelTask {
    my $self     = shift;
    my $taskName = shift;
    my $task     = shift;

    unless( $taskName ) {
        error( 'SplitJoin: will not add unnamed parallel task' );
        return;
    }
    unless( $task ) {
        error( 'SplitJoin: will not add undef parallel task' );
        return;
    }
    if( exists( $self->{parallelTasks}->{$taskName} )) {
        warning( 'SplitJoin: parallel task exists already with this name, overriding:', $taskName );
    }
    $self->{parallelTasks}->{$taskName} = $task;

    unless( defined( $self->{parallelTasksSequence} )) {
        $self->{parallelTasksSequence} = [];
    }
    push @{$self->{parallelTasksSequence}}, $taskName;
}

##
# Set the join task
# $task: the task to set
sub setJoinTask {
    my $self     = shift;
    my $task     = shift;

    unless( $task ) {
        error( 'SplitJoin: will not add undef join task' );
        return;
    }
    if( exists( $self->{joinTask} )) {
        warning( 'SplitJoin: join task was previously set, overriding' );
    }
    $self->{joinTask} = $task;
}

##
# @Overridden
sub getSubtasks {
    my $self = shift;

    my @ret = ();
    if( defined( $self->{splitTask} )) {
        push @ret, $self->{splitTask};
    }
    if( defined( $self->{parallelTasks} ) && %{$self->{parallelTasks}} ) {
        push @ret, values %{$self->{parallelTasks}};
    }
    if( defined( $self->{joinTask} )) {
        push @ret, $self->{joinTask};
    }
    return @ret;
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
                    error( "ERROR when executing " . $run->replaceVariables( $splitTask->getName()) . ". Stopping." );
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
                        error( "ERROR when executing " . $run->replaceVariables( $task->getName()) . ". Stopping." );
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
                        error( "ERROR when executing " . $run->replaceVariables( $joinTask->getName()) . ". Stopping." );
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
