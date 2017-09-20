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

use base qw( Macrobuild::HasNamedValues );
use fields qw( input output children task );

use UBOS::Logging;
use UBOS::Utils;
use overload q{""} => 'toString';

##
# Constructor.
# $input: has of input data for this task run
# $delegate: where to go to for variables not found locally
# $task: the Task that is run by this TaskRun
sub new {
    my $self     = shift;
    my $input    = shift;
    my $delegate = shift;
    my $task     = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->SUPER::new( $delegate );

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
        my $taskName = $self->{task}->getName();
        if( $taskName ) {
            return 'TaskRun for ' . $taskName;
        } else {
            return 'TaskRun for unnamed task of type ' . ref( $self->{task} );
        }
    } else {
        return 'TaskRun for undef Task';
    }
}

##
# @Overridden
sub getLocalValueNames {
    my $self = shift;

    return ();
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
# Enables a Task to read one of its own properties. Variable references
# are automatically expanded.
# If no such value can be found, a fatal error occurs.
#
# $name: the name of the value
# return: the value, or undef
sub getProperty {
    my $self = shift;
    my $name = shift;

    my $ret = $self->{task}->getProperty( $name );
    if( defined( $ret ) && $self->{delegate} ) {
        $ret = $self->{delegate}->replaceVariables( $ret ); # one level up
    } else {
        fatal( 'No such property value found:', $name, '. Task:', $self->{task}->getName() );
    }
    return $ret;
}

##
# Enables a Task to read one of its own properties. Variable references
# are automatically expanded.
# If no such value can be found, return the default (which may be undef).
#
# $name: the name of the value
# $default: the default value, if no other value can be found
# return: the value, or undef
sub getPropertyOrDefault {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    my $ret = $self->{task}->getPropertyOrDefault( $name, $default );
    if( defined( $ret )) {
        $ret = $self->replaceVariables( $ret );
    }
    return $ret;
}

##
# @Overridden
sub getUnresolvedValue {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    my $ret = $self->{task}->getPropertyOrDefault( $name, undef );
    unless( defined( $ret )) {
        $ret = $self->{task}->getUnresolvedTaskConstantOrDefault( $name, undef );
    }
    unless( defined( $ret )) {
        $ret = $self->{delegate}->getUnresolvedValue( $name, $default );
    }
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
