#
# Delegates to SearchReplace.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package TestTasks::DelegatingSearchReplace;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields qw( DelegatingSearchReplaceTestPattern );

use Macrobuild::Task;
use TestTasks::SearchReplace;
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

    $self->setDelegate( TestTasks::SearchReplace->new(
            'name'        => 'Delegated',
            'pattern'     => '${DelegatingSearchReplaceTestPattern}bb',
            'replacement' => 'X',
    ));

    return $self;
}

1;


