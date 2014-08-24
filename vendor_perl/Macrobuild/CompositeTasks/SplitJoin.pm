# 
# A build Task that first runs a splitting task, then two or more parallel tasks,
# and then a joining Task.
#
# This file is part of macrobuild.
# (C) 2014 Indie Computing Corp.
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
use fields qw( splitTask splitParallelTaskInputs parallelTasks joinTask );

use Macrobuild::Logging;

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
                    error( "ERROR when executing " . $splitTask->name() . ". Stopping." );
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
        foreach my $taskName ( sort keys %{$self->{parallelTasks}} ) { # make this a predictable sequence
			my $task = $self->{parallelTasks}->{$taskName};

            my $childRun = $run->createChildRun( $self->{splitParallelTaskInputs} ? $nextIn->{$taskName} : $nextIn );

            my $taskRet = $task->run( $childRun );

            if( $taskRet ) {
                if( $taskRet < 0 ) {
                    $ret = $taskRet;
                    if( $self->{stopOnError} ) {
                        error( "ERROR when executing " . $task->name() . ". Stopping." );
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
                        error( "ERROR when executing " . $joinTask->name() . ". Stopping." );
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

    $run->taskEnded( $self, $nextIn );

    return $ret;
}

##
# Set the settings object
sub setSettings {
    my $self        = shift;
    my $newSettings = shift;

    foreach my $t ( values %{$self->{parallelTasks}}, $self->{splitTask}, $self->{joinTask} ) {
        if( $t ) {
            $t->setSettings( $newSettings );
        }
    }
}    

1;
