# 
# Delegates to another task which a subclass needs to define
# in the constructor
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

package Macrobuild::CompositeTasks::Delegating;

use base qw( Macrobuild::Task );
use fields qw( delegate );

use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my %args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->{showInLog} = 0;
    
    $self->SUPER::new( %args );
    
    return $self;
}

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;

    my $in = $run->taskStarting( $self );

    my $ret;
    my $out;
    if( defined( $self->{delegate} )) {
        my $childRun = $run->createChildRun( $in );
        
        $ret = $self->{delegate}->run( $childRun );
        $out = $childRun->getOutput();
        
    } else {
        error( "No delegate defined for delegating task", $self->name );
        $ret = -1;
        $out = {};
    }

    $run->taskEnded( $self, $out, $ret );

    return $ret;
}

1;
