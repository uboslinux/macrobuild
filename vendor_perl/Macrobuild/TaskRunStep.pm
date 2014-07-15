# 
# A step in a TaskRun
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

package Macrobuild::TaskRunStep;

use fields qw( task status in out subRuns );

# status: 0: not started, 1: started, 2: completed

##
# Constructor
sub new {
    my $self = shift;
    my $in   = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{task}    = undef;
    $self->{status}  = 0;
    $self->{in}      = $in;
    $self->{out}     = undef;
    $self->{subRuns} = [];

    return $self;
}

1;
