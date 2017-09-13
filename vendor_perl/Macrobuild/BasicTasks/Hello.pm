# 
# Says hello or another message.
#
# This file is part of macrobuild.
# (C) 2014-2017 Indie Computing Corp.
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

package Macrobuild::BasicTasks::Hello;

use UBOS::Logging;

use base qw( Macrobuild::Task );
use fields qw( message );

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $msg = $run->get( 'message', 'Message from task Hello: Hello! You called?' );
    print( "$msg\n" );

    return $self->SUCCESS;
}    

1;

