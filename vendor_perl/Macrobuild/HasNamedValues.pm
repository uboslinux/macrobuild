#
# Abstract superclass for those objects that carry named values.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::HasNamedValues;

use fields qw( _resolver );

use overload;
use UBOS::Logging;

##
# Constructor.
# $resolver: where to go to for variables not found locally
sub new {
    my $self     = shift;
    my $resolver = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{_resolver} = $resolver;

    return $self;
}

##
# Obtain the name, for debugging.
sub getName {
    my $self = shift;

    fatal( 'Subclasses must override', ref( $self ) . '::name()' );
}

##
# Obtain the resolver
# return: the resolver
sub getResolver {
    my $self = shift;

    return $self->{_resolver};
}

##
# Set the resolver, if it has not been set before
# $resolver: the resolver
sub setResolver {
    my $self     = shift;
    my $resolver = shift;

    if( defined( $self->{_resolver} )) {
        fatal( 'Have resolver already, cannot set again' );
    }
    $self->{_resolver} = $resolver;
}

##
# Obtain a named value.
# If no such value can be found, a fatal error occurs.
#
# $name: the name of the value
# return: the value
sub getValue {
    my $self    = shift;
    my $param   = shift;

    my $ret = $self->getValueOrDefault( $param, undef );
    if( defined( $ret )) {
        return $ret;
    }
    fatal( $self, '- cannot resolve value:', $param );
}

##
# Obtain a named value.
# If no such value can be found, return the default value (which may
# be undef.
#
# $name: the name of the value
# $default: the default value, if no other value can be found
# return: the value, or undef
sub getValueOrDefault {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    fatal( 'Must override:', ref( $self ) . '::getValueOrDefault' );
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
# $replacementTrace: to provide useful user feedback, we track all to-be-resolved strings
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self             = shift;
    my $s                = shift;
    my $extraDict        = shift;
    my $unresolvedOk     = shift;
    my $replacementTrace = shift; # array of array[ $self, $s, $var-in-$s, $replacement, $getValueTrace ]

    unless( defined( $replacementTrace )) {
        $replacementTrace = [];
    }
    push @$replacementTrace, [ $self, $s ];

    unless( defined( $s )) {
        $self->_replacementError( 'Cannot replace variables in undef', $replacementTrace );
        return undef;
    }

    my $type = ref( $s );
    if( 'ARRAY' eq $type ) {
        my @ret;
        foreach my $ss ( @$s ) {
            my $ret = $self->_scaryReplace( $ss, $s, $unresolvedOk, $extraDict, $replacementTrace );

            push @ret, $ret;
        }
        return \@ret;

    } elsif( 'HASH' eq $type ) {
        my %ret;
        foreach my $key ( sort keys %$s ) {
            my $value    = $s->{$key};

            my $newKey   = $self->_scaryReplace( $key,   $s, $unresolvedOk, $extraDict, $replacementTrace );
            my $newValue = $self->_scaryReplace( $value, $s, $unresolvedOk, $extraDict, $replacementTrace );

            $ret{$newKey} = $newValue;
        }
        return \%ret;

    } else {
        my $ret = $self->_scaryReplace( $s, $s, $unresolvedOk, $extraDict, $replacementTrace );
        return $ret;
    }
}

##
# Isolate the scary regex.
sub _scaryReplace {
    my $self             = shift;
    my $current          = shift;
    my $s                = shift;
    my $unresolvedOk     = shift;
    my $extraDict        = shift;
    my $replacementTrace = shift;

    my %replacedAlready = ();
    my $resolver        = $self;
    my $ret             = $current;

    unless( defined( $ret )) {
        error( 'Undefined value in _scaryReplace:', $s, $unresolvedOk, $replacementTrace );
        return undef;
    }

    while( $resolver ) {
        my %replacingNow = ();

        $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$resolver->_replacement(
                $1, $s, $unresolvedOk, $extraDict, \%replacedAlready, \%replacingNow, $replacementTrace )/ge;
        if( $ret !~ m!\$\{[^?]! ) {
            last;
        }

        %replacedAlready = ( %replacedAlready, %replacingNow );
        $resolver = $resolver->getResolver();
    }
    return $ret;
}

##
# Helper method to determine the replacement string in the replaceVariables method.
# $matched: the matched pattern
# $s: the string containing the variables
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# $extraDict: hack to allow one more variable to be defined
# $replacedAlready: to avoid loops in definitions, this tracks the variables replaced in previous passes
# $replacingNow: to avoid loops in definitions, this tracks the variables replaced in the current pass
# $replacementTrace: to provide useful user feedback, we track all to-be-resolved strings
# return: the replacement string
sub _replacement {
    my $self             = shift;
    my $matched          = shift;
    my $s                = shift;
    my $unresolvedOk     = shift;
    my $extraDict        = shift;
    my $replacedAlready  = shift;
    my $replacingNow     = shift;
    my $replacementTrace = shift;

    push @{$replacementTrace->[-1]}, $matched;

    if( exists( $replacedAlready->{$matched} )) {
        $self->_replacementError(
                'Recursive definition encountered when attempting to resolve variable:' . $matched,
                $replacementTrace );
        return '${? ' . $matched . '}';
    }
    $replacingNow->{$matched} += 1;

    my $ret = undef;
    my $getValueTrace = [];
    if( $extraDict && exists( $extraDict->{$matched} )) {
        $ret = $extraDict->{$matched};
        push @$getValueTrace, $extraDict;
    }

    unless( defined( $ret )) {
        $ret = $self->getValueOrDefault( $matched, undef, $getValueTrace );
        # no need to add to getValueTrace, getValueOrDefault will have done that already
    }
    push @{$replacementTrace->[-1]}, $ret;
    push @{$replacementTrace->[-1]}, $getValueTrace;

    # we cannot replace things that aren't strings or aren't 1-length arrays
    if( defined( $ret )) {
        if( 'ARRAY' eq ref( $ret )) {
            if( @$ret == 1 ) {
                $ret = $ret->[0];
            } else {
                $self->_replacementError(
                        "Cannot replace '$matched' in string '$s' with array: "
                                . join( ' ', @$ret ),
                        $replacementTrace );
                return $matched;
            }
        } elsif( 'HASH' eq ref( $ret )) {
                $self->_replacementError(
                        "Cannot replace '$matched' in string '$s' with hash: "
                                . join( ', ', map { "'$_' => '" . $ret->{$_} . "'" } keys %$ret ),
                        $replacementTrace );
            return $matched;
        }

    } else {
        if( $unresolvedOk ) {
            if( $matched =~ m!^\?! ) {
                $ret = '{' . $matched . '}'; # got that before, no more ?
            } else {
                $ret = '${? ' . $matched . '}';
            }
        } else {
            $self->_replacementError(
                    "Unknown variable '$matched' in string: '$s'",
                    $replacementTrace );
        }
    }
    return $ret;
}

##
# Emit an error when variable resolution was not successful
# $message: the reason for the error
# $replacementTrace: trace of the attempts that were made.
sub _replacementError {
    my $self             = shift;
    my $message          = shift;
    my $replacementTrace = shift;

    my $fullMessage = $message;
    if( defined( $replacementTrace ) && @$replacementTrace ) {
        $fullMessage .= "\nReplacement trace, in sequence:";

        foreach my $row ( @$replacementTrace ) {
            $fullMessage .= "\n * String '" . $row->[1] . "'";
            if( @$row > 2 ) {
                $fullMessage .= " -- replacing var '" . $row->[2] . "'";
                if( @$row > 3 && defined( $row->[3] )) {
                    $fullMessage .= " with value '" . $row->[3] . "'";
                }
                $fullMessage .= " (against " . $row->[0] . '"';

                if( @$row > 4 ) {
                    foreach my $valueTrace ( @{$row->[4]} ) {
                        $fullMessage .= "\n   - tried getValueOrDefault() on " . $valueTrace;
                    }
                }
            }
        }
    }

    if( UBOS::Logging::isTraceActive() ) {
        $fullMessage .= "\nStack trace:\n";
    }

    fatal( $fullMessage );
}

1;

