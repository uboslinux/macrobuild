#
# Does nothing and reports that in the return code. For testing.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::BasicTasks::DoneNothing;

use Macrobuild::Task;

use base qw( Macrobuild::Task );
use fields;

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    return DONE_NOTHING;
}

1;

