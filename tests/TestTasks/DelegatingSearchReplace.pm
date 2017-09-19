#
# Delegates to SearchReplace.
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

package TestTasks::DelegatingSearchReplace;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields;

use Macrobuild::Task;
use TestTasks::SearchReplace;
use UBOS::Logging;

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

                $task->setDelegate( new TestTasks::SearchReplace->new(
                    'name'        => 'Delegated',
                    'pattern'     => '${DelegatingSearchReplaceTestPattern}bb',
                    'replacement' => 'X',
                ));

                return SUCCESS;
            });


    return $self;
}

1;


