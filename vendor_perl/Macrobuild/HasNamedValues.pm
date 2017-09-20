#
# Abstract superclass for those objects that carry named values.
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

package Macrobuild::HasNamedValues;

use fields qw( delegate );

use UBOS::Logging;

##
# Constructor.
# $delegate: where to go to for variables not found locally
sub new {
    my $self     = shift;
    my $delegate = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{delegate} = $delegate;

    return $self;
}

##
# Obtain the name, for debugging.
sub getName {
    my $self = shift;

    fatal( 'Subclasses must override', ref( $self ) . '::name()' );
}

##
# Obtain the delegate settings object, if any
# return: the delegate
sub getDelegate {
    my $self = shift;

    return $self->{delegate};
}

##
# Obtain a named value. Variable references are automatically expanded.
# If no such value can be found, a fatal error occurs.
#
# $name: the name of the value
# return: the value, or undef
sub getValue {
    my $self    = shift;
    my $param   = shift;

    my $ret = $self->getUnresolvedValue( $param, undef );
    if( defined( $ret )) {
        $ret = $self->replaceVariables( $ret );
    } else {
        fatal( 'Cannot resolve value:', $param );
    }
    return $ret;
}

##
# Obtain a named value. Variable references are automatically expanded.
# If no such value can be found, return the default value (which may
# be undef.
#
# $name: the name of the value
# $default: the default value, if no other value can be found
# return: the value, or undef
sub getValueOrDefault {
    my $self    = shift;
    my $name   = shift;
    my $default = shift;

    my $ret = $self->getUnresolvedValue( $name, $default );
    if( defined( $ret )) {
        $ret = $self->replaceVariables( $ret );
    }
    return $ret;
}

##
# Obtain a named value, starting locally and traversing up to delegates
# as needed. Variable references are not expanded.
# This must be overridden by subclasses.
#
# $name: the name of the value
# $default: the default value, if no other value can be found
# return: the value, or undef
sub getUnresolvedValue {
    my $self    = shift;
    my $name   = shift;
    my $default = shift;

    fatal( 'Must override:', ref( $self ) . '::getUnresolvedValue' );
}

##
# Get the names of all locally named values.
#
# return: a list
sub getLocalValueNames {
    my $self = shift;

    fatal( 'Must override:', ref( $self ) . '::getLocalValueNames' );
}

##
# Replace all variables in a string. A variable is referred to by
# the syntax '${xxx}' where 'xxx' is the variable name. If '$' is
# preceded by a backslash, this occurrence is skipped.
# $s: the string containing the references to the variables
# $extraDict: hack to allow one more variable to be defined
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self         = shift;
    my $s            = shift;
    my $extraDict    = shift;
    my $unresolvedOk = shift;

    unless( defined( $s )) {
        error( 'Cannot replace variables in undef' );
        use Carp;
        print carp( 'stack trace' );

        return undef;
    }
    my $MAX_REPLACEMENTS = 5;

    my $type = ref( $s );
    if( 'ARRAY' eq $type ) {
        my @ret;
        foreach my $ss ( @$s ) {
            my $ret = $ss;
            my $done;

            my %replacedAlready = ();
            for( my $i=0 ; $i<$MAX_REPLACEMENTS ; ++$i ) {
                my %replacingNow = ();
                ( $ret, $done ) = $self->_scaryReplace( $ret, $s, $unresolvedOk, $extraDict, \%replacedAlready, \%replacingNow );
                if( $done ) {
                    last;
                }
                %replacedAlready = ( %replacedAlready, %replacingNow );
            }
            push @ret, $ret;
        }

        return \@ret;

    } elsif( 'HASH' eq $type ) {
        my %ret;
        foreach my $key ( sort keys %$s ) {
            my $value    = $s->{$key};
            my $newKey   = $key;
            my $newValue = $value;
            my $keyDone;
            my $valueDone;

            my %keysReplacedAlready = ();
            for( my $i=0 ; $i<$MAX_REPLACEMENTS ; ++$i ) {
                my %replacingNow = ();
                ( $newKey, $keyDone ) = $self->_scaryReplace( $newKey, $s, $unresolvedOk, $extraDict, \%keysReplacedAlready, \%replacingNow );
                if( $keyDone ) {
                    last;
                }
                %keysReplacedAlready = ( %keysReplacedAlready, %replacingNow );
            }

            my %valuesReplacedAlready = ();
            for( my $i=0 ; $i<$MAX_REPLACEMENTS ; ++$i ) {
                my %replacingNow = ();
                ( $newValue, $valueDone ) = $self->_scaryReplace( $newValue, $s, $unresolvedOk, $extraDict, \%valuesReplacedAlready, \%replacingNow );
                if( $valueDone ) {
                    last;
                }
                %valuesReplacedAlready = ( %valuesReplacedAlready, %replacingNow );
            }
            $ret{$newKey} = $newValue;
        }

        return \%ret;

    } else {
        my $ret = $s;
        my $done;

        my %replacedAlready = ();
        for( my $i=0 ; $i<$MAX_REPLACEMENTS ; ++$i ) {
            my %replacingNow = ();
            ( $ret, $done ) = $self->_scaryReplace( $ret, $s, $unresolvedOk, $extraDict, \%replacedAlready, \%replacingNow );
            if( $done ) {
                last;
            }
            %replacedAlready = ( %replacedAlready, %replacingNow );
        }

        return $ret;
    }
}

##
# Isolate the scary regex.
sub _scaryReplace {
    my $self            = shift;
    my $current         = shift;
    my $s               = shift;
    my $unresolvedOk    = shift;
    my $extraDict       = shift;
    my $replacedAlready = shift;
    my $replacingNow    = shift;

    my $ret = $current;
    $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$self->_replacement( $1, $s, $unresolvedOk, $extraDict, $replacedAlready, $replacingNow )/ge;

    if( $ret =~ m!\$\{[^?]! ) {
        return( $ret, 0 );
    } else {
        return( $ret, 1 );
    }
}

##
# Helper method to determine the replacement string in the replaceVariables method.
# $matched: the matched pattern
# $s: the string containing the variables
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# $extraDict: hack to allow one more variable to be defined
# $replacedAlready: to avoid loops in definitions, this tracks the variables replaced in previous passes
# $replacingNow: to avoid loops in definitions, this tracks the variables replaced in the current pass
# return: the replacement string
sub _replacement {
    my $self            = shift;
    my $matched         = shift;
    my $s               = shift;
    my $unresolvedOk    = shift;
    my $extraDict       = shift;
    my $replacedAlready = shift;
    my $replacingNow    = shift;

    if( exists( $replacedAlready->{$matched} )) {
        error( 'Recursive definition encountered when attempting to resolve variable:', $matched );
        return '${? ' . $matched . '}';
    }
    $replacingNow->{$matched} += 1;

    my $ret = undef;
    if( $extraDict && exists( $extraDict->{$matched} )) {
        $ret = $extraDict->{$matched};
    }
    unless( defined( $ret )) {
        $ret = $self->getUnresolvedValue( $matched );
    }
    # we cannot replace things that aren't strings or aren't 1-length arrays
    if( defined( $ret )) {
        if( 'ARRAY' eq ref( $ret )) {
            if( @$ret == 1 ) {
                $ret = $ret->[0];
            } else {
                error( 'Cannot replace', $matched, 'in string', $s, 'with array:', @$ret );
                return $matched;
            }
        } elsif( 'HASH' eq ref( $ret )) {
            error( 'Cannot replace', $matched, 'in string', $s, 'with hash', keys %$ret );
            return $matched;
        }
    }
    unless( defined( $ret )) {
        if( $unresolvedOk ) {
            if( $matched =~ m!^\?! ) {
                $ret = '{' . $matched . '}'; # got that before, no more ?
            } else {
                $ret = '${? ' . $matched . '}';
            }
        } else {
            my $resTrace = "Resolution trace:";
            my $del = $self;
            while( $del ) {
                $resTrace .= "\n * " . $del->getName();
                if( UBOS::Logging::isTraceActive()) {
                    $resTrace .= ' (' . join( ', ', map { "$_=" . $del->getUnresolvedValue( $_ )} $del->getLocalValueNames()) . ')';
                }
                $del = $del->getDelegate();
            }

            fatal( 'Unknown variable ' . $matched . ' in string:', $s, $resTrace );
        }
    }
    return $ret;
}

1;

