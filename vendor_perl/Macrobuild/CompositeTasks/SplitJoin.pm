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
use fields qw( _splitTask _parallelTasks _parallelTasksSequence _joinTask splitSplitTaskOutput splitPrefix );

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
    if( exists( $self->{_splitTask} )) {
        warning( 'SplitJoin: split task was previously set, overriding' );
    }
    $self->{_splitTask} = $task;
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
    if( exists( $self->{_parallelTasks}->{$taskName} )) {
        warning( 'SplitJoin: parallel task exists already with this name, overriding:', $taskName );
    }
    $self->{_parallelTasks}->{$taskName} = $task;

    unless( defined( $self->{_parallelTasksSequence} )) {
        $self->{_parallelTasksSequence} = [];
    }
    push @{$self->{_parallelTasksSequence}}, $taskName;
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
    if( exists( $self->{_joinTask} )) {
        warning( 'SplitJoin: join task was previously set, overriding' );
    }
    $self->{_joinTask} = $task;
}

##
# @Overridden
sub getSubtasks {
    my $self = shift;

    my @ret = ();
    if( defined( $self->{_splitTask} )) {
        push @ret, $self->{_splitTask};
    }
    if( defined( $self->{_parallelTasks} ) && %{$self->{_parallelTasks}} ) {
        push @ret, values %{$self->{_parallelTasks}};
    }
    if( defined( $self->{_joinTask} )) {
        push @ret, $self->{_joinTask};
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

    my $splitTask = $self->{_splitTask};
    if( $splitTask ) {
        $previousChildRun = $run->createChildRun( $splitTask );
        my $taskRet       = $splitTask->run( $previousChildRun );

        if( $taskRet ) {
            if( $taskRet < 0 ) {
                $ret = $taskRet;
                if( $self->{stopOnError} ) {
                    error( 'During execution of split task and stopping:', $splitTask );
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
        if( defined( $self->{_parallelTasksSequence} )) {
            foreach my $task ( @{$self->{_parallelTasksSequence}} ) {
                if( !exists( $self->{_parallelTasks}->{$task} )) {
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
        map {   my $t = $_;
                unless( exists( $inSequence{$t} )) {
                    push @realSequence, $t;
                }
            } sort keys %{$self->{_parallelTasks}};

        my $outData = {};

        foreach my $taskName ( @realSequence ) {
            my $task = $self->{_parallelTasks}->{$taskName};

            my $previousSplitChildRun = $previousChildRun;
            if( $previousChildRun && $splitTask && $self->{splitSplitTaskOutput} ) {
                my $previousChildRunOutput = $previousChildRun->getOutput();
                my $sectionName            = defined( $self->{splitPrefix} ) ? $self->{splitPrefix} . $taskName : $taskName;
                my $thisInput;
                if( exists( $previousChildRunOutput->{$sectionName} )) {
                    $thisInput = $previousChildRunOutput->{$sectionName};
                } else {
                    $thisInput = {};
                }
                $previousSplitChildRun = Macrobuild::TaskRun->new( $thisInput, $run, $self );
            }
            my $childRun = $run->createChildRun( $task, $previousSplitChildRun );
            my $taskRet  = $task->run( $childRun );

            if( $taskRet ) {
                if( $taskRet < 0 ) {
                    $ret = $taskRet;
                    if( $self->{stopOnError} ) {
                        error( 'During execution of parallel task and stopping:', $task );
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
        my $joinTask = $self->{_joinTask};
        if( $joinTask ) {
            $previousChildRun = $run->createChildRun( $joinTask, $previousChildRun );

            my $taskRet = $joinTask->run( $previousChildRun );

            if( $taskRet ) {
                if( $taskRet < 0 ) {
                    $ret = $taskRet;
                    if( $self->{stopOnError} ) {
                        error( 'During execution of join task and stopping: ', $joinTask );
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
