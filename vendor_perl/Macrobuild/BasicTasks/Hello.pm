#
# Says hello or another message.
#
# Copyright (C) 2014 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::BasicTasks::Hello;

use Macrobuild::Task;

use base qw( Macrobuild::Task );
use fields qw( message );

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $msg = $self->getPropertyOrDefault( 'message', 'Message from task Hello: Hello! You called?' );
    print( "$msg\n" );

    return SUCCESS;
}

1;

