#!/usr/bin/perl -w
#
# perlblaster.pl
#	Perl Defense Blaster
#		Created on:  Fri Aug 18 14:12:04 CDT 2000
#		By: David Slimp
#
#	This is an attempt at creating an ascii graphic
#	arcade game fully in perl.


use Term::ReadKey;
use Curses;
use strict;

my $VERSION='0.0.1';
my $debug=0;

##
## Initialization
##

my(@missilex, @missiley, $missileturn, $maxmissiles);
my($enemyx, $enemyy, $enemyspeed, $showspeed);

initscr();
my $key="";
my $score=0;
my @termsize=GetTerminalSize;
my $maxx		= $termsize[0];
my $maxy		= $termsize[1];
my $x		= int($maxx/2);
my $y		= $maxy-2;
#$missilex	= $x;
#$missiley	= $y;
my($tot);
$missileturn=0;
$maxmissiles=1;

ReadMode 4;	# non breaking mode
addstr($y, $x, 'A');

&StartEnemy;


##
## Main Loop
##

while ( $key ne "q" ) {
	while (not defined ($key = ReadKey(-1))) {

		if ( @missilex ) { &MoveMissile($missileturn) }

		&MoveEnemy;

		$showspeed=$enemyspeed*10000;
		$tot=@missilex;
		addstr($maxy-1, 1, "score: $score    EnemySpeed: $showspeed       $tot  turn=$missileturn    (q = quit)");
		refresh; 
			
	}


	$key eq "4" and $x>0 and $x--;
	$key eq "6" and $x<$maxx and $x++;
	#if ($key eq "5" and not $missile) { &StartMissile }
	if ($key eq "5" and @missilex<$maxmissiles ) { &StartMissile }

	addstr($y, $x-1, ' A ');
	refresh; 
}

ReadMode 0;	# normal mode


##
## Subroutines
##

sub StartMissile {
	system("play laser.wav &");
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
	$missiley[$mnum]-=.002;
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
	$enemyspeed=($score/30)*.001;
	$enemyspeed < .001 and $enemyspeed=.001;
}

sub MoveEnemy {
	addstr($enemyy, $enemyx, ' ');
	$enemyy+=$enemyspeed;
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
	system("play explos.wav &");

	# FIXME: This should be a more interesting explosion at some point, but should not slow (suspend) the game while the explosion is occuring
	addstr($y, $x, ' ');
}
