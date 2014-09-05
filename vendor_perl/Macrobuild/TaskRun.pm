# 
# Inputs, outputs, and history information for the run of a Task
#
# It comes with a state machine:
# 1. Created with inputs
# 2. taskStarting (which returns input)
# 3. taskEnding, providing output
# Either:
# 4a: Go to #2, which makes last output the next input
# 4b: Get final output
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

package Macrobuild::TaskRun;

use fields qw( settings interactive steps );

use Macrobuild::TaskRunStep;
use UBOS::Logging;

##
# Constructor
# $settings: the settings
# $in: the input values, if any
# $interactive: if 1, wait for user input at the end of each task
sub new {
    my $self        = shift;
    my $settings    = shift;
    my $in          = shift;
    my $interactive = shift;

    unless( ref $self ) {
        $self = fields::new( $self );
    }
    $self->{settings}    = $settings;
    $self->{interactive} = $interactive;
    $self->{steps} = [
            new Macrobuild::TaskRunStep( $in )
    ];

    return $self;
}

##
# Create a child TaskRun object for child Tasks
# $in: the input values
# return: the child TaskRun
sub createChildRun {
    my $self = shift;
    my $in   = shift;

    my $ret;
    if( @{$self->{steps}} ) {
        my $lastElement = $self->{steps}->[-1];
        
        if( $lastElement->{status} == 1 ) {
            $ret = new Macrobuild::TaskRun( $self->{settings}, $in, $self->{interactive} );

            push @{$lastElement->{subRuns}}, $ret;
            
        } elsif( $lastElement->{status} == 0 ) {
            error( "Cannot create a child run if a task has not been started", $lastElement->{task} );
        } else {
            error( "Cannot create a child run if a task that has ended already", $lastElement->{task} );
        }

    } else {
        error( "Cannot create a child run if no task has been started" );
    }
    return $ret;
}

##
# Get the settings object
# return: the settings object
sub getSettings {
    my $self = shift;

    return $self->{settings};
}

##
# Obtain the steps
# return: the steps
sub getSteps {
    my $self = shift;

    return $self->{steps};
}

##
# Indicate a new task is starting
# $task: the task that is starting
# return: input values for this task
sub taskStarting {
    my $self = shift;
    my $task = shift;

    if( @{$self->{steps}} ) {
        my $lastElement = $self->{steps}->[-1];
        if( $lastElement->{status} == 0 ) {
            $lastElement->{status} = 1;
            $lastElement->{task}   = $task;

            info( 'Starting task', sub { $self->{settings}->replaceVariables( $task->name ) } );
            debug( 'Task input:',  sub { _resultsAsString( $lastElement->{in} ) }  );

            return $lastElement->{in};
            
        } elsif( $lastElement->{status} == 1 ) {
            error( "Task running already, cannot be started again", $task );
            return undef;
        } else {
            error( "Task ended already, cannot be started again", $task );
            return undef;
        }
    } else {
        error( "Cannot start task, no inputs were set" );
        return undef;
    }
}

##
# Indicate a task has completed
# $task: the task that has completed
# $output: the output of the task that has completed
sub taskEnded {
    my $self   = shift;
    my $task   = shift;
    my $output = shift;

    debug( 'Task output:', sub { _resultsAsString( $output ) }  );

    if( $self->{interactive} ) {
        print "Task ended. Hit return to continue.\n";
        getc();
    }

    if( @{$self->{steps}} ) {
        my $lastElement = $self->{steps}->[-1];
        
        if( $lastElement->{status} == 1 ) {
            if( $task == $lastElement->{task} ) {
                $lastElement->{out}    = $output;
                $lastElement->{status} = 2;

                # go step forward
                my $newStep = new Macrobuild::TaskRunStep( $output );
                push @{$self->{steps}}, $newStep;
            } else {
                error( "Cannot end a different task than has been started", $task, $lastElement->{task} );
            } 
            
        } elsif( $lastElement->{status} == 0 ) {
            error( "Cannot end a task that has not started", $task, $lastElement->{task} );
        } else {
            error( "Cannot end a task that has ended already", $task, $lastElement->{task} );
        }

    } else {
        error( "Cannot end a task if none has started" );
    }
}

##
# Get the output values from this run
# return: the output
sub getOutput {
    my $self = shift;

    if( @{$self->{steps}} >= 2 ) {
        my $lastElement = $self->{steps}->[-2];
        if( $lastElement->{status} == 2 ) {
            return $lastElement->{out};

        } else {
            error( "Last task not properly ended" );
            return $lastElement->{out}; # do something
        }
    } else {
        fatal( "Cannot get output before any task was run" );
    }
}

##
# For debugging
sub resultsAsString {
    my $self   = shift;
    my $indent = shift || 0;

    my $is = '    ' x $indent;

    my $ret;
    for( my $i=0 ; $i<@{$self->{steps}} ; ++$i ) {
        my $s = $self->{steps}->[$i];
        my $t = $s->{task};
        if( $t ) {
            $ret .= "\n${is}Step #$i: " . $t->name;
            foreach my $subRun ( @{$s->{subRuns}} ) {
                $ret .= "\n${is}  sub-runs: " . $subRun->resultsAsString( $indent+1 );
            }

        } elsif( $i != @{$self->{steps}} -1 ) {
            error( "No task set in step $i of " . @{$self->{steps}} );
        }
    }
    return $ret;
}

##
# For debugging
sub _resultsAsString {
    my $obj    = shift;
    my $indent = shift || 0 ;
    
    my $is = '    ' x $indent;

    if( !defined( $obj )) {
		return '<undef>';
	} elsif( ref( $obj ) eq 'HASH' ) {
        return "{\n"
               . join( '',
                       map {
                           "$is$_ => " . _resultsAsString( $obj->{$_}, $indent+1 ) . "\n"
                        } keys %$obj )
               . "$is}";
    } elsif( ref( $obj ) eq 'ARRAY' ) {
        return "[\n"
               . join( '',
                       map {
                           "$is" . _resultsAsString( $_, $indent+1 ) . "\n"
                        } @$obj )
               . "$is]";
    } else {
        return $obj;
    }
}

##
# Get the value of a variable from the settings
# $name: name of the variable
# return: value of the variable
# $default: value to return if variable does not exist
sub getVariable {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    return $self->{settings}->getVariable( $name, $default );
}

##
# Replace all variables in a string from the settings.
# $s: the string containing the variables
# $undefIfUndef: return undef if not all variables could be replaced
# return: the string with variables returned, or undef
sub replaceVariables {
    my $self         = shift;
    my $s            = shift;
    my $undefIfUndef = shift;

    return $self->{settings}->replaceVariables( $s, $undefIfUndef );
}

1;
