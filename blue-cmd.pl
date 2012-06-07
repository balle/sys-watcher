#!/usr/bin/perl
#
# [Description]
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Just a simple script to execute a command if an 
# bluetooth device was found or is gone.
# This script can for example be used to lock or shutdown
# your computer if you leave place carring your bluetooth
# mobile phone with you.
#
# Example:
# ./blue-cmd.pl -d -b aa:bb:cc:aa:bb:cc -a "xscreensaver-command -lock" -t "touch /tmp/muh"
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# [Author]
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Programmed by Bastian Ballmann
# E-Mail: balle@chaostal.de
# Web:: http://www.datenterrorist.de
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# [License]
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# This program is free software; you can redistribute
# it and/or modify it under the terms of the
# GNU General Public License version 2 as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
# Last update 10.05.2004
#
# Remember... There is no spoon. And take the red pill!


###[ Loading modules ]###

use strict;
use Getopt::Std;


###[ Configuration ]###

# Where to find hcitool?
my $hcitool="/usr/bin/hcitool";

# Where to find l2ping?
my $lping = "/sbin/l2ping";

# Read and check parameter
my %opts;
getopts('a:b:dlst:v', \%opts);
usage() unless(defined $opts{'b'} && defined $opts{'a'} && defined $opts{'t'});
usage() if $ARGV[0] eq "--help";


###[ Main part ]###

# Exec command?
my $exec_away = 1;
my $exec_there = 1;
my $command;

# Just scan?
if($opts{'s'})
{
    open(HCI,"$hcitool scan|") or die "$!\n";
    map { print; } <HCI>;
    close(HCI);
    exit(0);
}

# lookup via hci or l2ping?
if($opts{'l'})
{
    die "You must be root to use l2ping!\n" if $> != 0;
    $command = "$lping -c 1 $opts{'b'}";
}
else
{
    $command = "$hcitool name $opts{'b'}";
}

# Become a daemon?
daemonize() if $opts{'d'};

# Endless scanning loop
while(1)
{
    my $found = 0;

    # Trying to get name of btaddr
    open(SCAN,"$command|") or die "$!\n";
    my @result = <SCAN>;
    close(SCAN);

    # Check if the device was found
    if($opts{'l'})
    {
	map { $found = 1 if $_ =~ /$opts{'b'}/; } @result;
    }
    else
    {
	$found = 1 if scalar(@result) > 0;
    }

    # Device was found and command should be executed
    if($found && $exec_there)
    {
	print "Exec $opts{'t'}\n" if $opts{'v'};
	$exec_there = 0;
	$exec_away = 1;
	system($opts{'t'});
    }

    # Device is gone and command should be executed
    elsif( ($found == 0) && ($exec_away == 1) )
    {
	print "Exec $opts{'a'}\n" if $opts{'v'};
	$exec_away = 0;
	$exec_there = 1;
	system($opts{'a'});
    }

    close(HCI);
}


###[ Subroutines ]###

# Print usage
sub usage
{
    print "$0 -d -l -s -v -b <btaddr> -a <away_cmd> -t <there_cmd>\n";
    print "-d(aemonize)\n";
    print "-l use l2ping instead of hcitool name\n";
    print "-s(can)\n";
    print "-v(erbose)\n";
    exit(0);
}

# Become a daemon
sub daemonize
{
    exit(0) if fork();
    chdir("/");
    setpgrp(0,0);
    close(STDIN);
    close(STDOUT);
    close(STDERR);
}
