# 
# An abstract Task for the build.
#
# This file is part of Macrobuild.
# (C) 2014 Johannes Ernst
#
# Macrobuild is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Macrobuild is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Macrobuild.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

package Macrobuild::Task;

use fields qw( name stopOnError );

use Macrobuild::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{stopOnError} = 1; # can be overridden

    for( my $i=0; $i<@args ; $i += 2 ) {
        $self->{$args[$i]} = $args[$i+1];
    }
    return $self;
}

##
# Get the name of this task
sub name {
    my $self = shift;

    return $self->{name} || ref( $self );
}

##
# Get a named parameter
# $parName: name of the parameter
sub parameter {
    my $self    = shift;
    my $parName = shift;

    return ( defined( $self->{pars} ) && $self->{pars}->{$parName} ) || undef;
}

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
# return value: -1: error. 0: success. 1: nothing to do
sub run {
    my $self = shift;
    my $run  = shift;

    error( "Class must define run method: " . ref( $self ));

    return -1;
}

1;
