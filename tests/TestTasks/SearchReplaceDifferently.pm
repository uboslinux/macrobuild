# 
# Takes the input, runs it through three different SearchReplace tasks,
# and puts it together.
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

package TestTasks::SearchReplaceDifferently;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields;

use Macrobuild::CompositeTasks::MergeValues;
use Macrobuild::CompositeTasks::SplitJoin;
use TestTasks::SearchReplace;

##
# Constructor
sub new {
    my $self = shift;
    my %args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    
    $self->SUPER::new( %args );

    $self->{delegate} = Macrobuild::CompositeTasks::SplitJoin->new(
        'name'          => 'SearchReplaceDifferently',
        'splitTask'     => TestTasks::SearchReplace->new(
            'pattern'     => 'a',
            'replacement' => 'A' ),
        'parallelTasks' => {
            'one' => TestTasks::SearchReplace->new(
                'pattern'     => 'A',
                'replacement' => '1' ),
            'two' => TestTasks::SearchReplace->new(
                'pattern'     => 'A',
                'replacement' => '2' ),
            'three' => TestTasks::SearchReplace->new(
                'pattern'     => 'A',
                'replacement' => '3' ),
        },
        'joinTask'      => Macrobuild::CompositeTasks::MergeValues->new(
            'name'        => 'MergeValues',
            'keys'        => ['one', 'three' ] # leave out 'two' for testing purposes
        ));

    return $self;
}

1;
