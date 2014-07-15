# 
# A build Task that takes the JSON subtrees below several keys, and merges it
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

package MacroBuild::CompositeTasks::MergeValuesTask;

use base qw( MacroBuild::Task );
use fields qw( keys );

use Macrobuild::Logging;

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;

    my $keys = $self->{keys};

    my $in = $run->taskStarting( $self );

    my $out = _merge( map { $in->{$_} } @$keys );

    $run->taskEnded( $self, $out );

    if( defined( $out ) && $out == -1 ) {
        return -1;
    } else {
        return 0;
    }
}

##
sub _merge {
    my @arguments = @_;

    my $type = undef;
    foreach my $arg ( @arguments ) {
        if( defined( $arg )) {
            if( defined( $type )) {
                if( $type ) {
                    if( $type ne ref( $arg )) {
                        error( "Cannot merge types:", $type, "vs.", ref( $arg ));
                        return -1;
                    }
                } else {
                    error( "Cannot merge strings" );
                    return -1;
                }
            } else {
                $type = ref( $arg );
            }
        }
    }

    my $ret;
    if( !defined( $type )) {
        # No input, nothing to do

    } elsif( $type eq "HASH" ) {
        $ret = {};

        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                while( my( $valueKey, $valueValue ) = each %$arg ) {
                    if( exists( $ret->{$valueKey} )) {
                        $ret->{$valueKey} = _merge( $ret->{$valueKey}, $valueValue );
                    } else {
                        $ret->{$valueKey} = $valueValue;
                    }
                }
            }
        }
        
    } elsif( $type eq "ARRAY" ) {
        $ret = [];

        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                foreach my $valueValue ( @$arg ) {
                    push @$ret, $valueValue;
                }
            }
        }

    } elsif( $type eq '' ) {
        foreach my $arg ( @arguments ) {
            if( defined( $arg )) {
                $ret = $arg; # there should be only one
            }
        }

    } else {
        error( "What is this", $type );
        return -1;
    }

    return $ret;
}

1;
