#
# Does nothing and reports an error in the return code. For testing.
#
# Copyright (C) 2014 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

package Macrobuild::BasicTasks::Fail;

use Macrobuild::Task;

use base qw( Macrobuild::Task );
use fields;

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    return FAIL;
}

1;

