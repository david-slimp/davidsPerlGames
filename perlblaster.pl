#!/usr/bin/perl -w
#
# perlblaster.pl  -  Perl Defense Blaster
#		Created on:  Fri Aug 18 14:12:04 CDT 2000
#		Author: David Slimp
#
# This is an attempt at creating an ascii graphic arcade game fully in perl.
#

use Term::ReadKey;
use Curses;
use Time::HiRes qw(time sleep);
use strict;

my $VERSION='0.0.1';	# THIS will need to get updated as we advance to the new stage of code
my $debug=0;

##
## Initialization
##

# Time control variables
my $enemy_update_interval = 1;  # seconds between each enemy movement
my $missile_update_interval = .1;  # seconds between each missile movement
my $last_enemy_update_time = 0;
my $last_missile_update_time = 0;
my $current_time = time;

my(@missilex, @missiley, $missileturn, $maxmissiles);
my($enemyx, $enemyy, $enemyspeed, $showspeed);

initscr();
my $key="";
my $score=0;
my @termsize=GetTerminalSize;
my $maxx		= $termsize[0]-1;
my $maxy		= $termsize[1];
my $x		= int($maxx/2);
my $y		= $maxy-3;
my($tot);
$missileturn=0;	# counter for which missile to move next
$maxmissiles=1;	# maximum number of missiles allowed on screen at once

ReadMode 4;	# non breaking mode
addstr($y, $x, 'A');

&StartEnemy;


##
## Main Loop
##

while ( $key ne "q" ) {
	$current_time = time   ; # get the current time

	$key = ReadKey(-1); # read a key without blocking
	defined $key or $key = ""; # if no key was pressed, set $key to ""


	# Update missile based on time
    if ($current_time - $last_missile_update_time > $missile_update_interval) {
        if ( @missilex ) { &MoveMissile($missileturn) }
            $last_missile_update_time = $current_time;
        }

    # Update enemy based on time
    if ($current_time - $last_enemy_update_time > $enemy_update_interval) {
        &MoveEnemy;
        $last_enemy_update_time = $current_time;
    }

	$showspeed=$enemyspeed*10;	# FIXME: $enemyspeed might now be used/needed anymore with Time::HiRes
	$tot=@missilex;
	addstr($maxy-2, 1, "score: $score    EnemySpeed: $showspeed       $tot  turn=$missileturn    (q = quit)");
	refresh; 
	
	$key eq "4" and $x>0 and $x--;
	$key eq "6" and $x<$maxx and $x++;
	if ($key eq "5" and @missilex<$maxmissiles ) { &StartMissile }
	addstr($y, $x-1, ' A ');
	
	refresh; 
	sleep(0.001);

}

ReadMode 0;	# normal mode
system("reset");	# reset the terminal (fixes hiding input characters)

##
## Subroutines
##

sub StartMissile {
	system("aplay laser.wav  &>/dev/null  &");	# FIXME: We need to find a way to play audio via PERL
	$missilex[@missilex]=$x;
	$missiley[@missiley]=$y;
}

sub MoveMissile {
	# mnum is a counter for the number of the currently moving missile
	# we increase the alias for the variable passed in to move the
	#	next missile, next time through
	my($mnum)=$_[0]++;
	$_[0]>=@missilex and $_[0]=0;

	$debug  and  addstr(3,3,"mnum=$mnum   missileturn=$_[0]")  and   refresh;

	addstr($missiley[$mnum], $missilex[$mnum], ' ');
	$missiley[$mnum]-=1;
	addstr($missiley[$mnum], $missilex[$mnum], '!');
	if ( $missiley[$mnum]<1 ) {
		&MissileStop($mnum);
		return;
	}
	if ( $missilex[$mnum] == $enemyx and $missiley[$mnum] < $enemyy) {
		&MissileHit($mnum);
		return;
	}
				
}

sub MissileHit {
	my($mnum)=@_;
	# FIXME: Perhaps the explosion should be run in parallel?
	&ExplodeEnemy($enemyx,$enemyy);

	#$missile=0;
	$score=$score+int($maxy-$enemyy);
	&StartEnemy;
}

sub MissileStop {
	my($mnum)=@_;
	$debug and addstr(1,1,"stopping missile # $mnum \n") and refresh and sleep(2);
	addstr($missiley[$mnum], $missilex[$mnum], ' ');
	splice(@missilex,$mnum,1,());
	splice(@missiley,$mnum,1,());
	$debug and addstr(1,1,"array contains :@missilex: \n") and refresh and sleep(4);
	
	#$missile=0;
}

sub StartEnemy {
	$enemyy=0;
	$enemyx=int(rand($maxx));
	$enemyspeed=($score/30)*.1;	# FIXME: Might not need $enemyspeed anymore with Time::HiRes
	$enemyspeed < .1 and $enemyspeed=.1;
}

sub MoveEnemy {
	addstr($enemyy, $enemyx, ' ');
	$enemyy+=1;
	addstr($enemyy, $enemyx, 'V');
	if ($enemyy >= $maxy) {
		addstr($enemyy, $enemyx, 'V');
		$score-=30;
		&StartEnemy;
	}
}

sub ExplodeEnemy {
	my($x,$y) = @_;
	
	# FIXME: We need to find a way to play audio via PERL
	system("aplay explos.wav &>/dev/null &");	# FIXME: We need to find a way to play audio via PERL

	# FIXME: This should be a more interesting explosion at some point, but should not slow (suspend) the game while the explosion is occuring
	addstr($y, $x, ' ');
}
