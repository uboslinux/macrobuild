# 
# A build Task that takes the JSON subtrees below several keys, and merges it
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

package Macrobuild::CompositeTasks::MergeValuesTask;

use base qw( Macrobuild::Task );
use fields qw( keys );

use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{showInLog} = 0;
    
    $self->SUPER::new( @args );
    
    return $self;
}

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;

    my $keys = $self->{keys};

    my $in = $run->taskStarting( $self );

    my $out = _merge( map { $in->{$_} } @$keys );

    if( defined( $out ) && $out == -1 ) {
        $run->taskEnded( $self, $out, -1 );
        return -1;
    } else {
        $run->taskEnded( $self, $out, 0 );
        return 0;
    }
}

##
sub _merge {
    my @arguments = @_;

    my $type = undef;
    foreach my $arg ( @arguments ) {
        if( defined( $arg )) {
            my $argType = ref( $arg );
            if( defined( $type )) {
                if( $argType && $type ne $argType ) {
                    error( "Cannot merge types:", $type, "vs.", $argType );
                    return 'Error merging types';
                }
            } else {
                $type = $argType;
            }
        }
    }

    my $ret;
    if( !defined( $type )) {
        # No input, nothing to do

    } elsif( $type eq 'HASH' ) {
        $ret = {};

        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                if( ref( $arg ) eq 'HASH' ) {
                    foreach my $valueKey ( keys %$arg ) {
                        my $valueValue = $arg->{$valueKey};

                        if( exists( $ret->{$valueKey} )) {
                            $ret->{$valueKey} = _merge( $ret->{$valueKey}, $valueValue );
                        } else {
                            $ret->{$valueKey} = $valueValue;
                        }
                    }
                } else {
                    $ret->{$arg} = {};
                }
            }
        }
        
    } elsif( $type eq 'ARRAY' ) {
        $ret = [];

        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                if( ref( $arg ) eq 'ARRAY' ) {
                    foreach my $valueValue ( @$arg ) {
                        push @$ret, $valueValue;
                    }
                } else {
                    push @$ret, $arg;
                }
            }
        }

    } elsif( $type eq '' ) {
        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                if( !defined( $ret )) {
                    # one, maybe the only one
                    $ret = $arg;
                } elsif( ref( $ret ) eq 'ARRAY' ) {
                    push @$ret, $arg;
                } else {
                    $ret = [ $ret, $arg ]; # push them into an array
                }
            }
        }

    } else {
        error( "What is this", $type );
        return -1;
    }

    return $ret;
}

1;
