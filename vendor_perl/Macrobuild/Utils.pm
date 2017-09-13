#
# Utility functions.
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

package Macrobuild::Utils;

use UBOS::Logging;

##
# Replace all variables in a string. A variable is referred to by
# the syntax '${xxx}' where 'xxx' is the variable name. If '$' is
# preceded by a backslash, this occurrence is skipped.
# $s: the string containing the references to the variables
# $vars: the place where to get the variable values from with ->get( $name )
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $s            = shift;
    my $vars         = shift;
    my $unresolvedOk = shift;

    debugAndSuspend( 'Macrobuild::Utils::replaceVariables', $s, $vars->name(), $unresolvedOk );

    unless( defined( $s )) {
        error( 'Cannot replace variables in undef' );
        use Carp;
        print carp( 'stack trace' );
        
        return undef;
    }

    my $ret = $s;
    for( my $i=0 ; $i<5 ; ++$i ) {
        # expand up to 5 times
        $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/_replacement( $1, $s, $vars, $unresolvedOk )/ge;
        unless( $ret =~ m!\$\{^?! ) { # dear Perl: really! This time no \ in front of ?
            last;
        }
    }

    return $ret;
}

##
# Helper method to determine the replacement string in the replaceVariables method.
# $matched: the matched pattern
# $s: the string containing the variables
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# return: the replacement string
sub _replacement {
    my $matched      = shift;
    my $s            = shift;
    my $vars         = shift;
    my $unresolvedOk = shift;

    my $ret = $vars->get( $matched );
    # we cannot replace things that aren't strings or aren't 1-length arrays
    if( defined( $ret ) && 'ARRAY' eq ref( $ret ) && @$ret == 1 ) {
        $ret = $ret->[0];
    }
    unless( defined( $ret )) {
        if( $unresolvedOk ) {
            if( $matched =~ m!^\?! ) {
                $ret = '{' . $matched . '}'; # got that before, no more ?
            } else {
                $ret = '${? ' . $matched . '}';
            }
        } else {
            fatal( 'Unknown variable ' . $matched . ' in string:', $s );
        }
    }
    return $ret;
}

1;

