# 
# Looks for a certain pattern in the input, and replaces it with another
# in the output.
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

package TestTasks::SearchReplace;

use Storable qw(dclone);
use UBOS::Logging;

use base qw( Macrobuild::Task );
use fields qw( pattern replacement );

##
# @Overrides
sub runImpl {
    my $self = shift;
    my $run  = shift;

    my $count = 0;
    my $out = $self->_replace( $run->getInput, $run, \$count );

    $run->setOutput( $out );

    if( $count ) {
        return $self->SUCCESS;
    } else {
        return $self->DONE_NOTHING;
    }
}

sub _replace {
    my $self   = shift;
    my $in     = shift;
    my $run    = shift;
    my $countP = shift;

    my $pattern     = Macrobuild::Utils::replaceVariables( $self->{pattern},     $run );
    my $replacement = Macrobuild::Utils::replaceVariables( $self->{replacement}, $run );

    my $type = ref( $in );
    my $ret;
    if( $type eq 'ARRAY' ) {
        $ret = [];
        for my $e ( @$in ) {
            push @$ret, $self->_replace( $e, $run, $countP );
        }
    } elsif( $type eq 'HASH' ) {
        $ret = {};
        for my $key ( keys %$in ) {
            $ret->{$self->_replace( $key, $run, $countP )} = $self->_replace( $in->{$key}, $run, $countP );
        }
    } else {
        $ret = $in;
        $$countP += ( $ret =~ s!$pattern!$replacement!g );
    }
    return $ret;
}

1;

