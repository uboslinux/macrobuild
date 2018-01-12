#
# Takes the input, runs it through three different SearchReplace tasks,
# and puts it together.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
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
    my @args = @_;

    unless( ref $self ) {
        $self = fields::new( $self );
    }

    $self->SUPER::new( @args );

    $self->setSplitTask( TestTasks::SearchReplace->new(
            'pattern'     => 'a',
            'replacement' => 'A' ));

    $self->addParallelTask(
            'one',
            TestTasks::SearchReplace->new(
                    'pattern'     => 'A',
                    'replacement' => '1' ));

    $self->addParallelTask(
            'two',
            TestTasks::SearchReplace->new(
                    'pattern'     => 'A',
                    'replacement' => '2' ));

    $self->addParallelTask(
            'three',
            TestTasks::SearchReplace->new(
                    'pattern'     => 'A',
                    'replacement' => '3' ));

    $self->setJoinTask( Macrobuild::BasicTasks::MergeValues->new(
            'name'        => 'MergeValues',
            'keys'        => ['one', 'three' ] # leave out 'two' for testing purposes
    ));

    return $self;
}

1;
