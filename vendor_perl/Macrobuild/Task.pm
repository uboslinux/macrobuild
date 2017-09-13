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

use fields qw( name stopOnError showInLog );

use UBOS::Logging;
use overload q{""} => 'toString';

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{name}        = undef; # can be overridden
    $self->{stopOnError} = 1;     # can be overridden
    $self->{showInLog}   = 1;     # can be overridden

    for( my $i=0; $i<@args ; $i+=2 ) {
        eval {
            $self->{$args[$i]} = $args[$i+1];
        } || error( 'Cannot assign: there is no property', $args[$i], 'on objects of type', ref( $self ));
    }
    return $self;
}

##
# Get the name of this task
sub name {
    my $self = shift;

    return $self->{name};
}

##
# Get the type of this task
sub type {
    my $self = shift;

    return ref( $self );
}

##
# Get a value that's locally specificied in this instance of Task
# @param name the name of the value
# return: the value, or undef
sub get {
    my $self  = shift;
    my $param = shift;

    my $ret = undef;
    eval {
        $ret = $self->{$param};
    }; # ignore error
    return $ret;
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
# return value: SUCCESS, FAIL, or DONE_NOTHING
sub run {
    my $self = shift;
    my $run  = shift;

    debugAndSuspend( 'About to run task:', $self, 'with', $run );

    my $ret = $self->runImpl( $run );

    debugAndSuspend( 'Done running task:', $self, 'with', $run );

    return $ret;
}

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

    if( $self->{name} ) {
        return ref( $self ) . "(name=$self->{name})";
    } else {
        return overload::StrVal( $self );
    }
}

1;
