#
# Definitions for running macrobuild. Multiple instances of this class
# may delegate to each other, to get a Pascal-like hierarchy of
# namespaces that may (partially) override each other.
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

package Macrobuild::Constants;

use Macrobuild::Utils;
use UBOS::Logging;

use fields qw( name vars delegate );

##
# Constructor
# $name: name of the settings object, in case there is more than one
# $vars: variables available to the tasks
# $delegate: a delegate Settings objects to consult if a value was not available locally
sub new {
    my $self     = shift;
    my $name     = shift;
    my $vars     = shift || {};
    my $delegate = shift || undef;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{name}     = $name;
    $self->{vars}     = $vars;
    $self->{delegate} = $delegate;

    return $self;
}

##
# Create a new Constants object by reading from a Perl file and delegating
# to the provided delegate. The file must be a Perl file and return a
# hash.
# $fileName: the file to read
# $delegate: the delegate Constants
# return the new Constants object
sub readAndCreate {
    my $self     = shift;
    my $fileName = shift;
    my $delegate = shift;

    my $vars = eval "require '$fileName';" || fatal( 'Cannot read file', "$fileName\n", $@ );

    return $self->new( $fileName, $vars, $delegate );
}

##
# Get name of the settings object
# return: name
sub name {
    my $self = shift;

    return $self->{name};
}

##
# Obtain the delegate settings object, if any
# return: the delegate
sub getDelegate {
    my $self = shift;
    
    return $self->{delegate};
}

##
# Obtain a named value. If such a named value does not exist here,
# we traverse up the delegation hierarchy.
# 
# $name: the name of the value
# $default: the default value, if no other value can be found
# return: the value, or undef
sub get {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    my $ret;
    if( exists( $self->{vars}->{$name} ) && defined( $self->{vars}->{$name} )) {
        $ret = Macrobuild::Utils::replaceVariables( $self->{vars}->{$name}, $self );

    } elsif( defined( $self->{delegate} )) {
        $ret = $self->{delegate}->get( $name );
    }
    if( !defined( $ret ) && defined( $default )) {
        $ret = Macrobuild::Utils::replaceVariables( $default, $self );
    }

    return $ret;
}

##
# Obtain all values of a named value, including overridden ones.
#
# $name: the name of the value
# $resolve: if true, attempt to resolve all values
# $appendHere: append the values to this array, or create a new one
# return: array of the values, the first of which is the actual value. Others
#         are overridden values
sub getAll {
    my $self       = shift;
    my $name       = shift;
    my $resolve    = shift || 0;
    my $appendHere = shift || [];

    if( exists( $self->{vars}->{$name} )) {
        my $value = $self->{vars}->{$name};
        if( $resolve ) {
            $value = Macrobuild::Utils::replaceVariables( $value, $self, 1 );
        }
        push @{$appendHere}, $value;
    }
    if( $self->{delegate} ) {
        $self->{delegate}->getAll( $name, $resolve, $appendHere );
    }
    return $appendHere;
}

##
# Obtain all obtainable variables recursively, with all values, including
# overridden ones.
#
# $resolve: if true, attempt to resolve all values
# $insertHere: insert the values into this hash, or create a new one
# return: hash of variable name to array of values, the first of which is the actual
#         value. Others are overridden values.
sub getAllWithAllValues {
    my $self       = shift;
    my $resolve    = shift || 0;
    my $insertHere = shift || {};

    foreach my $key ( keys %{$self->{vars}} ) {
        my $value = $self->{vars}->{$key};
        unless( exists( $insertHere->{$key} )) {
            $insertHere->{$key} = [];
        }
        if( $resolve ) {
            $value = Macrobuild::Utils::replaceVariables( $value, $self, 1 );
        }
        push @{$insertHere->{$key}}, $value;
    }
    if( $self->{delegate} ) {
        $self->{delegate}->getAllWithAllValues( $resolve, $insertHere );
    }
    return $insertHere;
}

1;
