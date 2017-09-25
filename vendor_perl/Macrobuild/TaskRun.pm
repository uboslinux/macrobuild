#
# Inputs, outputs, local variables and other contextual information about
# the run of a Task.
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

package Macrobuild::TaskRun;

use fields qw( input output children task );

use UBOS::Logging;
use UBOS::Utils;
use overload q{""} => 'toString';

##
# Constructor.
# $input: has of input data for this task run
# $task: the Task that is run by this TaskRun
sub new {
    my $self     = shift;
    my $input    = shift;
    my $task     = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{input}    = $input;
    $self->{output}   = {};
    $self->{children} = undef;
    $self->{task}     = $task;

    return $self;
}

##
# Obtain name. Derived from the task's name.
# return: the name
sub getName {
    my $self = shift;

    if( defined( $self->{task} )) {
        return 'TaskRun for ' . $self->{task};
    } else {
        return 'TaskRun for undef Task';
    }
}

##
# Obtain the input of this TaskRun.
# return: the input
sub getInput {
    my $self = shift;

    return $self->{input};
}

##
# Obtain the output of this TaskRun.
# return: the output
sub getOutput {
    my $self = shift;

    return $self->{output};
}

##
# Set the output of this TaskRun.
# $output: the output
sub setOutput {
    my $self   = shift;
    my $output = shift;

    $self->{output} = $output;
}

##
# Create a child TaskRun object for child Tasks
#
# $sibTask: the Task that is run by this child TaskRun
# $previousChildRun: if given, use its output as the new TaskRun's inputs. If
#                    not given, use this TaskRun's inputs as the new TaskRun's
#                    inputs
# return: the child TaskRun
sub createChildRun {
    my $self             = shift;
    my $subTask          = shift;
    my $previousChildRun = shift;

    unless( $self->{children} ) {
        $self->{children} = [];
    }

    my $inputs = $previousChildRun ? $previousChildRun->getOutput() : $self->getInput();
    my $ret = Macrobuild::TaskRun->new( $inputs, $self, $subTask );
    return $ret;
}


##
# Convert to string
# return string
sub toString {
    my $self = shift;

    my $ret = overload::StrVal( $self ) . '( name="' . $self->getName();
    my $sep = '", ';
    if( UBOS::Logging::isTraceActive() ) {
        use Data::Dumper;

       if( $self->{input} ) {
           $ret .= $sep . 'in=' . Dumper( $self->{input} );
           $sep = ', ';
       }
       if( $self->{output} ) {
           $ret .= $sep . 'out=' . Dumper( $self->{output} );
           $sep = ', ';
       }

    } elsif( UBOS::Logging::isInfoActive() ) {
       if( $self->{input} ) {
           $ret .= $sep . '#in=' . ( keys %{$self->{input}} );
           $sep = ', ';
       }
       if( $self->{output} ) {
           $ret .= $sep . '#out=' . ( keys %{$self->{output}} );
           $sep = ', ';
       }
    } else {
       if( $self->{input} ) {
           $ret .= $sep . 'in';
           $sep = ', ';
       }
       if( $self->{output} ) {
           $ret .= $sep . 'out';
           $sep = ', ';
       }
    }
    $ret .= ' )';
    return $ret;
}

1;
