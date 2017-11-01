my $settings = {
    'shortcuts' => {
        'something'                       => 'else',
        'search-replace-with'             => [ 'TestTasks::SearchReplace', 'pattern=a', 'replacement=A' ],
        'search-replace-without'          => [ 'TestTasks::SearchReplace' ],
        'search-replace-without-indirect' => [ 'search-replace-without' ]
    }
};

$settings;
