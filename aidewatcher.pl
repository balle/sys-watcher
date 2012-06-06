#!/usr/bin/perl

###[ Loading modules ]###

use Env qw(IFS);
use strict;


###[ Config ]###

# Wanna debug??
my $debug = 1;

# Path to festival
my $festival = "/usr/bin/festival";

# Path to AIDE
my $aide = "/usr/bin/aide";
my $db = "/media/stick/aide.db";


###[ MAIN PART ]###

# Environment manipulation
$IFS = "/";

# You need to be r00t
die "You need EUID 0.\n" unless $> == 0;

# Check files
die "$festival is not an executable!\n" unless -x $festival;
die "$aide is not an executable!\n" unless -x $aide;

unless(-f $db)
{
	system("echo 'AIDE database cannot be found! I am dying! I am dyiiing!' | $festival --tts");
        die "Cannot find AIDE database\n";
}

# Run AIDE check
my $start = time();
print "Running AIDE check...\n" if $debug;
open(LOG,"$aide --check|") or die "$!\n";

# Read logfile line by line
while(<LOG>) 
{
        if($_ =~ /found differences/i)
        {
        	print "echo 'Filesystem has changed! I repeat! Filesystem has changed! Check it now!' | $festival --tts\n" if $debug;
        	system("echo 'Filesystem has changed! I repeat! Filesystem has changed! Check it now!' | $festival --tts");
        }
}

close(LOG);
my $stop = time();
my $secs = $stop - $start;
print "Check took $secs seconds.\n" if $debug;

# EOF dude.