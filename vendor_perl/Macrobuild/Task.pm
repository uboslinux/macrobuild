#
# An abstract Task for the build.
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

package Macrobuild::Task;

use base qw( Macrobuild::HasNamedValues );
use fields qw( name stopOnError showInLog );

use UBOS::Logging;
use overload q{""} => 'toString';

use Exporter qw( import );
our @EXPORT = qw( SUCCESS FAIL DONE_NOTHING );

##
# Constructor
sub new {
    my $self     = shift;
    my @args     = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->SUPER::new( undef ); # set later

    $self->{name}        = undef; # can be overridden
    $self->{stopOnError} = 1;     # can be overridden
    $self->{showInLog}   = 1;     # can be overridden

    for( my $i=0; $i<@args ; $i+=2 ) {
        eval {
            $self->{$args[$i]} = $args[$i+1];
            1; # otherwise we can't set Undef
        } || fatal( 'Cannot assign: there is no property "' . $args[$i] . '" on objects of type', ref( $self ));
    }
    return $self;
}

##
# Set the resolver, if it has not been set before
# $resolver: the resolver
sub setResolver {
    my $self     = shift;
    my $resolver = shift;

    $self->SUPER::setResolver( $resolver ); # may fatal out

    if( $resolver ) {
        foreach my $key ( grep { ! /^_/ } keys %$self ) {
            my $value    = $self->{$key};
            if( $value ) {
                my $newValue = $resolver->replaceVariables( $value );

                if( $newValue =~ m!\$\{\?! ) {
                    fatal( 'Cannot resolve variable:', $newValue );
                }

                $self->{$key} = $newValue;
            }
        }

        my @subtasks = $self->getSubtasks();
        foreach my $subtask ( @subtasks ) {
            $subtask->setResolver( $self );
        }
    }
}

##
# Get the name of this task
sub getName {
    my $self = shift;

    return $self->{name};
}

##
# Get the type of this task
sub getType {
    my $self = shift;

    return ref( $self );
}

##
# Return sub-tasks (if there are any).
# return: array of sub-tasks, may be empty
sub getSubtasks {
    my $self = shift;

    return ();
}

##
# Get a value that's locally specificied in this instance of Task
# @param name the name of the value
# return: the value, or undef
sub getProperty {
    my $self  = shift;
    my $param = shift;

    my $ret = undef;
    eval {
        $ret = $self->{$param};
        1; # otherwise the fatal triggers when $ret == undef
    } || fatal( 'This object of type', ref( $self ), 'does not have a property', $param, $ret );

    return $ret;
}

##
# Get a value that's locally specificied in this instance of Task.
# If the named property does not exist, or has no value, return the default
#
# @param name the name of the property
# @param default the default value
# return: the value, or undef
sub getPropertyOrDefault {
    my $self    = shift;
    my $param   = shift;
    my $default = shift;

    my $ret = undef;
    eval {
        $ret = $self->{$param};
    }; # ignore error
    unless( defined( $ret )) {
        $ret = $default;
    }
    return $ret;
}

##
# @Overridden
sub getValueOrDefault {
    my $self          = shift;
    my $name          = shift;
    my $default       = shift;
    my $getValueTrace = shift;

    if( defined( $getValueTrace )) {
        push @$getValueTrace, $self;
    }

    my $ret;
    if( exists( $self->{$name} ) && defined( $self->{$name} )) {
        $ret = $self->{$name};

    } elsif( defined( $self->getResolver() )) {
        $ret = $self->getResolver()->getValueOrDefault( $name, $default, $getValueTrace );

    } else {
        $ret = $default;
    }
    return $ret;
}

##
# @Overridden
sub getLocalValueNames {
    my $self = shift;

    return keys %{$self};
}

##
# If true, show this task in a log
sub showInLog {
    my $self = shift;

    return $self->{showInLog};
}

##
# Run this task.
# $run: the TaskRun object for the run
# $dry: if true, dry-run, do not run
# return value: SUCCESS, FAIL, or DONE_NOTHING
sub run {
    my $self = shift;
    my $run  = shift;
    my $dry  = shift;

    if( $dry ) {
        $self->_printRecursively();

        return DONE_NOTHING();

    } else {
        unless( debugAndSuspend( '++ About to run task:', $self, 'with', "\n" . $run->toString( 2 ) . "\n" )) {
            info( '++ About to run task:', $self );
        }

        my $ret = $self->runImpl( $run );

        unless( debugAndSuspend( '-- Done running task:', $self, 'with', "\n" . $run->toString( 2 ) . "\n", 'return code', $ret )) {
            if( $ret == FAIL() ) {
                info( '-- Task returned with error:', $self );
            }
        }

        return $ret;
    }
}

##
# Hierarchically print this task and its subtasks
# $remainingLevels: the maximum number of levels to print from here, or -1 for all
# $indent: current identation level
sub _printRecursively {
    my $self            = shift;
    my $remainingLevels = shift || -1;
    my $indent          = shift || '';

    my $taskName = $self->getName();
    unless( $taskName ) {
        $taskName = ref( $self );
    }
    print "$indent$taskName";
    if( UBOS::Logging::isTraceActive()) {
        print " (vars: " . join( ', ', map { "'$_' => '" . ( $self->{$_} || 'undef' ) . "'" } keys %$self ) . ")";
    }
    print "\n";

    if( $remainingLevels == -1 || --$remainingLevels > 0 ) {
        my $subindent = $indent . '  ';
        my @subtasks  = $self->getSubtasks();
        foreach my $subtask ( @subtasks ) {
            _printRecursively( $subtask, $remainingLevels, $subindent );
        }
    }
}


##
# Setup the task to be ready for running. By default, this does nothing.
##
# Implementation of the run method for this task.
# $run: the TaskRun object for the run
# return value: SUCCESS, FAIL, or DONE_NOTHING
sub runImpl {
    my $self = shift;
    my $run  = shift;

    error( "Class must define run method: " . ref( $self ));

    return $self->FAIL;
}

##
# The return code for tasks doing useful work successfully
sub SUCCESS {
    my $self = shift;

    return 0;
}

##
# The return code for tasks doing useful work unsuccessfully
sub FAIL {
    my $self = shift;

    return -1;
}

##
# The return code for tasks doing no useful work successfully
sub DONE_NOTHING {
    my $self = shift;

    return 1;
}

##
# Convert to string
# return string
sub toString {
    my $self = shift;

    my $name = $self->getName();
    if( $name ) {
        return ref( $self ) . "(name=$name)";
    } else {
        return overload::StrVal( $self );
    }
}

1;
