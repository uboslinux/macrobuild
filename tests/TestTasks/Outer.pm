#
# Delegates to Inner.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package TestTasks::Outer;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields qw( message );

use Macrobuild::Task;
use TestTasks::Inner;
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

    $self->setDelegate( TestTasks::Inner->new(
        'message' => '${message}-outer'
    ));

    return $self;
}

1;


