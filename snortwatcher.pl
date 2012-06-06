#!/usr/bin/perl


###[ Loading modules ]###

use Env qw(IFS);
use POSIX;
use strict;


###[ Config ]###

# Wanna debug??
my $debug = 0;

# Path to festival
my $festival = "/usr/bin/festival";

# Path to tail
my $tail = "/usr/bin/tail";

# Logfile
my $logfile = "/var/log/snort/alert";


###[ MAIN PART ]###

# Environment manipulation
$IFS = "/";

# You need to be r00t
die "You need EUID 0.\n" unless $> == 0;

# Check files
die "Logfile is a link!\n" if -l $logfile;
die "Logfile does not exist!\n" unless -f $logfile;
die "$festival is not an executable!\n" unless -x $festival;
die "$tail is not an executable!\n" unless -x $tail;

# Run in background
daemonize();

# Open log file
open(LOG,"$tail -f $logfile|") or die "$!\n";

# Read logfile line by line
while(<LOG>) 
{
        # Time and ips
        if($_ =~ /.+?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\:\d+?\s\-\>\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\:\d+/)
        {
        	my $srcip = $1;
                my $dstip = $2;

                $srcip = "unknown" unless $srcip =~ /[\d\.]/;
                $dstip = "unknown" unless $dstip =~ /[\d\.]/;

        	print "echo 'Network attack from host $srcip' | $festival --tts\n" if $debug;
        	system("echo 'Network attack from host $srcip' | $festival --tts");
        }
}

close(LOG);



###[ Subroutines ]###

# Run in background
sub daemonize
{
    print "Becoming a daemon!\nBye, bye... ;)\n" if $debug;
    my $pid = fork; exit if $pid;
    die "WhOooops! Fork failed!\n$!\n" unless defined($pid);
    close(STDIN);
    close(STDOUT) unless $debug;
    close(STDERR) unless $debug;
    POSIX::setsid();    
}

# EOF dude.