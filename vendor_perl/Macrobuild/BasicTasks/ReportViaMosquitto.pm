# 
# Report what happened in the build by publishing via mosquitto_pub
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

package Macrobuild::BasicTasks::ReportViaMosquitto;

use base qw( Macrobuild::Task );
use fields qw( fieldsChannels );

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;

    $run->taskStarting( $self ); # ignore input

    my $report = {};
    $self->_report( $run, $report );

    my $runChannel = $self->{fieldsChannels}->{''};
    if( $runChannel ) {
        $runChannel = $run->getSettings->replaceVariables( $runChannel, 1 );
        if( $runChannel ) {
            system( "mosquitto_pub -t '$runChannel' -m 'ran'" );
        }
    }
    if( %$report ) {
        while( my( $name, $value ) = each %$report ) {
            my $channel = $self->{fieldsChannels}->{$name};
            if( $channel ) {
                $channel = $run->getSettings->replaceVariables( $channel, 1 );
                if( $channel ) {
                    system( "mosquitto_pub -t '$channel' -m '$value'" );
                }
            }
        }
    }

    $run->taskEnded( $self, $report );

    if( %$report ) {
        return 0;
    } else {
        return 1;
    }
}

##
# Recursive into sub-runs
sub _report {
    my $self   = shift;
    my $run    = shift;
    my $report = shift;
    
    my $steps  = $run->getSteps;
    
    foreach my $field ( keys %{$self->{fieldsChannels}} ) {
        foreach my $step ( @$steps ) {
            foreach my $subRun ( @{$step->{subRuns}} ) {
                $self->_report( $subRun, $report );
            }
            if( defined( $step->{out}->{$field} )) {
                my $value = $step->{out}->{$field};
                my $type = ref( $value );
                my $msg;
                if( 'ARRAY' eq $type ) {
                    $msg = join( ' ', @$value );
                } elsif( 'HASH' eq $type ) {
                    $msg = join( ' ', map { "$_ => " . $value->{$_} } keys %$value );
                } else {
                    $msg = $value;
                }
                if( $report->{$field} ) {
                    if( $report->{$field} =~ m!\Q$msg\E(\((\d+)\))?! ) {
                        my $n = $2;
                        ++$n;
                        $report->{$field} =~ s!\Q$msg\E\(\d+\)!$msg($n)!;
                    } else {
                        $report->{$field} .= ' ' . $msg;
                    }
                    
                } else {
                    $report->{$field} = $msg;
                }
            }
        }
    }
}

1;

