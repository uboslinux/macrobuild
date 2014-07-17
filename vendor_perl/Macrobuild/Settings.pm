#
# Settings for the Build
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

package Macrobuild::Settings;

use Macrobuild::Logging;

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
# $undefIfUndef: return undef if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self         = shift;
    my $s            = shift;
    my $undefIfUndef = shift;

    my $ret = $s;
    $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$self->getVariable( $1, '${? ' . $1 . '}' )/ge;

    if( $ret =~ m!\$\{\?.*\}! ) {
        if( $undefIfUndef ) {
            $ret = undef;
        } else {
            fatal( "Unknown variable in string", $s, ", best we can do is", $ret );
        }
    }
    return $ret;
}

##
# Convenience method to ensure certain directories exist before or during a build.
# This creates missing parent directories recursively.
# @dirs: names of the directories, which may contain variable names
sub ensureDirectories {
    my $self = shift;
    my @dirs = @_;

    foreach my $dir ( @dirs ) {

        $dir = $self->replaceVariables( $dir );

        _ensureDirectory( $dir );
    }
}

sub _ensureDirectory {
    my $dir = shift;

    unless( -d $dir ) {
        if( $dir =~ m!^(.+)/([^/]+)/?$! ) {
            _ensureDirectory( $1 );
        }

        mkdir( $dir ) || fatal( 'Could not create directory', $dir );
    }
}

1;
