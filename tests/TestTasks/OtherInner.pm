#
# Delegates to Hello.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package TestTasks::OtherInner;

use base qw( Macrobuild::CompositeTasks::Delegating );
use fields qw( message );

use Macrobuild::BasicTasks::Hello;
use Macrobuild::Task;
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

    $self->setDelegate( Macrobuild::BasicTasks::Hello->new(
        'message' => '${THIS_IS_NOT_DEFINED_OtherInner}'
    ));

    return $self;
}

1;


