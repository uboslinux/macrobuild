#
# Delegates to the Fail task in various ways depending on parameters.
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

package TestTasks::OuterFail;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields qw( par );

use Macrobuild::BasicTasks::Fail;
use Macrobuild::BasicTasks::Hello;
use Macrobuild::CompositeTasks::Sequential;
use Macrobuild::CompositeTasks::SplitJoin;
use UBOS::Logging;

##
# Constructor
sub new {
    my $self = shift;
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->SUPER::new( @args );

    if( !defined( $self->{par} )) {
        # don't set a delegate

    } elsif( $self->{par} == 0 ) {
        $self->setDelegate( Macrobuild::BasicTasks::Hello->new( 'message' => 'All is well' ));

    } elsif( $self->{par} == 1 ) {
        $self->setDelegate( Macrobuild::BasicTasks::Fail->new());

    } elsif( $self->{par} == 2 ) {
        my $seq = Macrobuild::CompositeTasks::Sequential->new();
        $seq->appendTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Step 1' ));
        $seq->appendTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Step 2' ));
        $seq->appendTask( Macrobuild::BasicTasks::Fail->new());

        $self->setDelegate( $seq );

    } elsif( $self->{par} == 3 ) {
        my $split = Macrobuild::CompositeTasks::SplitJoin->new();
        $split->setSplitTask( Macrobuild::BasicTasks::Fail->new() );
        $split->addParallelTask( 'par1', Macrobuild::BasicTasks::Hello->new( 'message' => 'Par 1' ));
        $split->addParallelTask( 'par2', Macrobuild::BasicTasks::Hello->new( 'message' => 'Par 2' ));
        $split->setJoinTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Join' ));

        $self->setDelegate( $split );

    } elsif( $self->{par} == 4 ) {
        my $split = Macrobuild::CompositeTasks::SplitJoin->new();
        $split->setSplitTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Split' ));
        $split->addParallelTask( 'par1', Macrobuild::BasicTasks::Hello->new( 'message' => 'Par 1' ));
        $split->addParallelTask( 'par2', Macrobuild::BasicTasks::Hello->new( 'message' => 'Par 2' ));
        $split->setJoinTask( Macrobuild::BasicTasks::Fail->new() );

        $self->setDelegate( $split );

    } elsif( $self->{par} == 5 ) {
        my $split = Macrobuild::CompositeTasks::SplitJoin->new();
        $split->setSplitTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Split' ));
        $split->addParallelTask( 'par1', Macrobuild::BasicTasks::Hello->new( 'message' => 'Par 1' ));
        $split->addParallelTask( 'par2', Macrobuild::BasicTasks::Fail->new());
        $split->setJoinTask( Macrobuild::BasicTasks::Hello->new( 'message' => 'Join' ));

        $self->setDelegate( $split );

    } else {
        # don't set a delegate
    }

    return $self;
}

1;


