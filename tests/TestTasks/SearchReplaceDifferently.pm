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

use base qw( Macrobuild::CompositeTasks::SplitJoin );
use fields;

use Macrobuild::BasicTasks::MergeValues;
use Macrobuild::Task;
use TestTasks::SearchReplace;

##
# Constructor
sub new {
    my $self = shift;
    my %args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->SUPER::new(
            %args,
            'setup' => sub {
                my $run  = shift;
                my $task = shift;

                $task->setSplitTask( TestTasks::SearchReplace->new(
                        'pattern'     => 'a',
                        'replacement' => 'A' ));

                $task->addParallelTask(
                        'one',
                        TestTasks::SearchReplace->new(
                                'pattern'     => 'A',
                                'replacement' => '1' ));

                $task->addParallelTask(
                        'two',
                        TestTasks::SearchReplace->new(
                                'pattern'     => 'A',
                                'replacement' => '2' ));

                $task->addParallelTask(
                        'three',
                        TestTasks::SearchReplace->new(
                                'pattern'     => 'A',
                                'replacement' => '3' ));

                $task->setJoinTask( Macrobuild::BasicTasks::MergeValues->new(
                            'name'        => 'MergeValues',
                            'keys'        => ['one', 'three' ] # leave out 'two' for testing purposes
                        ));

                return SUCCESS;
            });

    return $self;
}

1;
