#!/usr/bin/perl
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

my $settings = {
    'shortcuts' => {
        'something'                       => 'else',
        'search-replace-with'             => [ 'TestTasks::SearchReplace', 'pattern=a', 'replacement=A' ],
        'search-replace-without'          => [ 'TestTasks::SearchReplace' ],
        'search-replace-without-indirect' => [ 'search-replace-without' ]
    }
};

$settings;
