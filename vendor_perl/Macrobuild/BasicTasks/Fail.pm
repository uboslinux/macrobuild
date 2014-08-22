# 
# A Task that always fails.
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

package Macrobuild::BasicTasks::Fail;

use base qw( Macrobuild::Task );
use fields;

use Macrobuild::Logging;

##
# Run this task.
# $run: the inputs, outputs, settings and possible other context info for the run
sub run {
    my $self = shift;
    my $run  = shift;
    
    my $in = $run->taskStarting( $self );

    error( "Task " . ref( $self ) . ": indeed, let's fail" );
    
    $run->taskEnded( $self, {} );

    return -1;
}

1;
