#
# Utility functions.
#
# This file is part of macrobuild.
# (C) 2014 Indie Computing Corp.
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

package Macrobuild::Utils;

use UBOS::Logging;

##
# Convenience method to ensure certain directories exist before or during a build.
# This creates missing parent directories recursively.
# @dirs: names of the directories
sub ensureDirectories {
    my @dirs = @_;

    foreach my $dir ( @dirs ) {
        _ensureDirectory( $dir );
    }
}

##
# Conventience method to ensure that about-to-created files have existing parent
# directories. This creates missing parent directories recursively.
# @files: names of the files whose parent directories may created.
sub ensureParentDirectoriesOf {
    my @files = @_;

    foreach my $file ( @files ) {
        if( $file =~ m!^(.+)/([^/]+)/?$! ) {
            _ensureDirectory( $1 );
        }
    }
}

sub _ensureDirectory {
    my $dir = shift;

    unless( -d $dir ) {
        ensureParentDirectoriesOf( $dir );

        mkdir( $dir ) || fatal( 'Could not create directory', $dir );
    }
}

1;
