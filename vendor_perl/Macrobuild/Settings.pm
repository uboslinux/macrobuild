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
# Add default values by reading the following file(s). Silently skip files
# that don't exist
# @settingsFiles: the settings files. These must be Perl files, returning a hash each
sub addDefaultSettingsFrom {
    my $self          = shift;
    my @settingsFiles = @_;

    my $delegate = $self->{delegate};
    foreach my $fileName ( reverse @settingsFiles ) {
        if( -e $fileName ) {
            my $vars = eval "require '$fileName';" || fatal( 'Cannot read file', "$fileName\n", $@ );

            $delegate = Macrobuild::Settings->new( $fileName, $vars, $delegate );
        }
    }
    $self->{delegate} = $delegate;
}

##
# Add variables by parsing the provided argument array.
# $args: array
# return: 0: ok, 1: syopsisHelpQuit, other: error message
sub addArgumentsFrom {
    my $self           = shift;
    my $args           = shift;
    my $interactiveP   = shift;
    my $verboseP       = shift;
    my $helpP          = shift;
    my $listShortcutsP = shift;
    my $printVars      = shift;
    my $logconfP       = shift;
    my $taskNamesP     = shift;

    my $vars = {};
    my $NOT_HERE = 'Option not allowed here: ';

    for( my $i=0 ; $i<@$args ; ++$i ) {
        if( $args->[$i] eq '-i' || $args->[$i] eq '--interactive' ) {
            if( defined( $interactiveP )) {
                $$interactiveP = 1;
            } else {
                return $NOT_HERE . '--interactive';
            }

        } elsif( $args->[$i] eq '-v' || $args->[$i] eq '--verbose' ) {
            if( defined( $verboseP )) {
                $$verboseP += 1;
            } else {
                return $NOT_HERE . '--verbose';
            }

        } elsif( $args->[$i] eq '-h' || $args->[$i] eq '--help' ) {
            if( defined( $helpP )) {
                $$helpP = 1;
            } else {
                return $NOT_HERE . '--help';
            }

        } elsif( $args->[$i] eq '-l' || $args->[$i] eq '--list-shortcuts' ) {
            if( defined( $listShortcutsP )) {
                $$listShortcutsP = 1;
            } else {
                return $NOT_HERE . '--list-shortcuts';
            }

        } elsif( $args->[$i] eq '-p' || $args->[$i] eq '--print-vars' ) {
            if( defined( $printVars )) {
                $$printVars = 1;
            } else {
                return $NOT_HERE . '--print-vars';
            }

        } elsif( $args->[$i] eq '-l' || $args->[$i] eq '--logConfFile' ) {
            if( defined( $logconfP )) {
                ++$i;
                if( $i < @$args ) {
                    $$logconfP = $args->[$i];
                } else {
                    return 1;
                }
            } else {
                return $NOT_HERE . '--logConfFile';
            }
            
        } elsif( $args->[$i] =~ m!^--?(\S+)$! ) {
            my $name = $1;
            ++$i;
            if( $i < @$args ) {
                if( exists( $vars->{$name} )) {
                    push @{$vars->{$name}}, $args->[$i];
                } else {
                    $vars->{$name} = [ $args->[$i] ];
                }
            } else {
                return 1;
            }
        } else {
            if( defined( $taskNamesP )) {
               push @$taskNamesP, $args->[$i];
            } else {
                return $NOT_HERE . '<taskname>';
            }
        }
    }
    if( keys %$vars ) {
        $self->{delegate} = Macrobuild::Settings->new( 'local settings', $vars, $self->{delegate} );
    }
    return 0;
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
# return: value
sub getVariable {
    my $self    = shift;
    my $n       = shift;
    my $default = shift;

    my $ret;
    if( exists( $self->{vars}->{$n} )) {
        $ret = $self->{vars}->{$n};
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
# Get all values of a variable through the chains of delegates
# $n: name of the variable
# $default: value to return if otherwise undef would be returned
# return: array of values
sub getAllVariableValues {
    my $self    = shift;
    my $n       = shift;
    my $default = shift;

    my @ret = ( $self->{vars}->{$n} );
    if( $self->{delegate} ) {
        push @ret, $self->{delegate}->getAllVariableValues( $n, $default );
    } else {
        push @ret, $default;
    }

    return @ret;
}

##
# Return all variables with their defined values. The values are arrays,
# with the first element being the official value, and subsequent elements
# values that have been overridden
# $resolve: during recursion, the $settings object to use for variable resolution
# $insertHere: during recursion, insert results in this hash
sub getAllVariables {
    my $self       = shift;
    my $resolve    = shift || $self;
    my $insertHere = shift || {};

    foreach my $key ( keys %{$self->{vars}} ) {
        unless( exists( $insertHere->{$key} )) {
            $insertHere->{$key} = [];
        }
        push @{$insertHere->{$key}}, $resolve->replaceVariables( $self->{vars}->{$key}, undef, 1 );
    }
    if( $self->{delegate} ) {
        $self->{delegate}->getAllVariables( $resolve, $insertHere );
    }
    return $insertHere;
}

##
# Replace all variables in a string. A variable is referred to by
# the syntax '${xxx}' where 'xxx' is the variable name. If '$' is
# preceded by a backslash, this occurrence is skipped.
# $s: the string containing the variables
# $additional: an optional hash with additional variable settings
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self         = shift;
    my $s            = shift;
    my $additional   = shift || {};
    my $unresolvedOk = shift;

    unless( defined( $s )) {
        error( 'Cannot replace variables in undef' );
        use Carp;
        print carp( 'stack trace' );
        
        return undef;
    }

    my $ret = $s;
    for( my $i=0 ; $i<5 ; ++$i ) {
        # expand up to 5 times
        $ret =~ s/(?<!\\)\$\{\s*([^\}\s]+(\s+[^\}\s]+)*)\s*\}/$self->_replacement( $1, $additional, $s, $unresolvedOk )/ge;
        unless( $ret =~ m!\$\{^?! ) { # dear Perl: really! This time no \ in front of ?
            last;
        }
    }

    return $ret;
}

##
# Helper method to determine the replacement string in the replaceVariables method.
# $matched: the matched pattern
# $additional: an optional hash with additional variable settings
# $s: the string containing the variables
# $unresolvedOk: return string containing unresolved variables if not all variables could be replaced
# return: the replacement string
sub _replacement {
    my $self         = shift;
    my $matched      = shift;
    my $additional   = shift;
    my $s            = shift;
    my $unresolvedOk = shift;

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
