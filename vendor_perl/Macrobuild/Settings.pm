#
# Settings for the Build
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

package Macrobuild::Settings;

use UBOS::Logging;

use fields qw( name vars );

##
# Constructor
# $name: name of the settings object, in case there is more than one
# $vars: variables available to the tasks
sub new {
    my $self = shift;
    my $name = shift;
    my $vars = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{name} = $name;
    $self->{vars} = $vars;

    my ( $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst ) = gmtime( time() );
    $self->{vars}->{tstamp} = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", ($year+1900), ( $mon+1 ), $mday, $hour, $min, $sec;
    
    return $self;
}

##
# Get name of the settings object
# return: name
sub getName {
    my $self = shift;

    return $self->{name};
}

##
# Get a variable
# $n: name of the variable
# $default: value to return if variable does not exist
sub getVariable {
    my $self    = shift;
    my $n       = shift;
    my $default = shift;

    return $self->{vars}->{ $n } || $default;
}

##
# Replace all variables in a string. A variable is referred to by
# the syntax '${xxx}' where 'xxx' is the variable name. If '$' is
# preceded by a backslash, this occurrence is skipped.
# $s: the string containing the variables
# $additional: an optional hash with additional variable settings
# $undefIfUndef: return undef if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self         = shift;
    my $s            = shift;
    my $additional   = shift || {};
    my $undefIfUndef = shift;

    unless( defined( $s )) {
        error( 'Cannot replace variables in undef' );
        use Carp;
        print carp( 'stack trace' );
        
        return undef;
    }

    my $ret = $s;
    $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$self->getVariable( $1, $additional->{$1} || '${? ' . $1 . '}' )/ge;

    if( $ret =~ m!\$\{\?.*\}! ) {
        if( $undefIfUndef ) {
            $ret = undef;
        } else {
            fatal( 'Unknown variable in string: ', $ret );
        }
    }
    return $ret;
}

1;
