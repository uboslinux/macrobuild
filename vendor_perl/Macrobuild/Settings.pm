#
# Settings for the Build
#
# This file is part of macrobuild.
# (C) 2014-2015 Indie Computing Corp.
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

use fields qw( name vars delegate );

##
# Constructor
# $name: name of the settings object, in case there is more than one
# $vars: variables available to the tasks
# $delegate: a delegate Settings objects to consult if a value was not available locally
sub new {
    my $self = shift;
    my $name = shift;
    my $vars = shift;
    my $delegate = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{name}     = $name;
    $self->{vars}     = $vars;
    $self->{delegate} = $delegate;

    my ( $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst ) = gmtime( time() );
    $self->{vars}->{tstamp} = sprintf "%.4d%.2d%.2d-%.2d%.2d%.2d", ($year+1900), ( $mon+1 ), $mday, $hour, $min, $sec;
    
    return $self;
}

##
# Add default values by reading the following file(s)
# @settingsFiles: the settings files. These must be Perl files, returning a hash each
sub addDefaultSettingsFrom {
    my $self          = shift;
    my @settingsFiles = @_;

    if( $self->{delegate} ) {
        fatal( 'Cannot add delegate, have one already: addDefaultSettingsFrom(', @settingsFiles, ')' );
    }
    my $delegate = undef;
    foreach my $fileName ( reverse @settingsFiles ) {
        my $vars = eval "require '$fileName';" || fatal( 'Cannot read file', "$fileName\n", $@ );
        
        $delegate = Macrobuild::Settings->new( $fileName, $vars, $delegate );
    }
    $self->{delegate} = $delegate;
}

##
# Get name of the settings object
# return: name
sub getName {
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
# Get a variable
# $n: name of the variable
# $default: value to return if otherwise undef would be returned
sub getVariable {
    my $self    = shift;
    my $n       = shift;
    my $default = shift;

    my $ret = $self->{vars}->{$n};
    if( $ret ) {
        if( 'ARRAY' eq ref( $ret ) && @$ret == 1 ) {
            return $ret->[0];
        } else {
            return $ret;
        }
    }
    if( $self->{delegate} ) {
        $ret = $self->{delegate}->getVariable( $n, $default );
    } else {
        $ret = $default;
    }
    return $ret;
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
    for( my $i=0 ; $i<5 ; ++$i ) {
        # expand up to 5 times
        $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$self->_replacement( $1, $additional, $s, $undefIfUndef )/ge;
        unless( $ret =~ m!\$\{^?! ) { # dear Perl: really! This time no \ in front of ?
            last;
        }
    }
    if( $undefIfUndef && $ret =~ m!\$\{\?! ) {
        $ret = undef;
    }

    return $ret;
}

##
# Helper method to determine the replacement string in the replaceVariables method.
# $matched: the matched pattern
# $additional: an optional hash with additional variable settings
# $s: the string containing the variables
# $undefIfUndef: return undef if not all variables could be replaced
# return: the replacement string
sub _replacement {
    my $self         = shift;
    my $matched      = shift;
    my $additional   = shift;
    my $s            = shift;
    my $undefIfUndef = shift;

    my $ret = $self->getVariable( $matched );
    # we cannot replace things that aren't strings or aren't 1-length arrays
    if( $ret && 'ARRAY' eq ref( $ret ) && @$ret == 1 ) {
        $ret = $ret->[0];
    }
    if( !$ret || ref( $ret )) {
        $ret = $additional->{$matched};

        if( $ret && 'ARRAY' eq ref( $ret ) && @$ret == 1 ) {
            $ret = $ret->[0];
        }
    }
    unless( $ret ) {
        if( $undefIfUndef ) {
            $ret = '${? ' . $matched . '}'
        } else {
            fatal( 'Unknown variable ' . $matched . ' in string:', $s );
        }
    }
    return $ret;
}

1;
