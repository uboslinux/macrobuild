#
# A build Task that performs a number of other Tasks in sequence.
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
                    error( "ERROR when executing " . $childTask->getName() . ". Stopping." );
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
