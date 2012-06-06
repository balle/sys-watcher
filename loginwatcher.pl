#!/usr/bin/perl
#
# Loginwatcher
#
# Just a simple script to use festival for
# reporting login/logouts
#
# Programmed by Bastian Ballmann
# Web: http://www.datenterrorist.de
# Mail: balle@chaostal.de
#
# Version: 0.4
# Last update: 10.11.2008
#
# License: GPLv2

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
my $logfile = "/var/log/auth.log";


###[ MAIN PART ]###

# Environment manipulation
$IFS = "/";

# Remember ssh login and dont report pam login that time
my $ssh_login = 0;

my %counter;

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
        # SSH successfull login
        if($_ =~ /sshd\[\d+\]:\s+Accepted password for (.+?) from (.+?) port/i)
        {
        	my $user = $1;
                my $host = $2;
                
                $user = "unknown" unless $user =~ /\w/;
                $host = "unknown" unless $host =~ /\w/;

        	print "echo 'User $user logged in from host $host' | $festival --tts\n" if $debug;
        	system("echo 'User $user logged in from host $host' | $festival --tts");

                $ssh_login = 1;
                
                $counter{$user} = 0;
        }

        # SSH failed login
        elsif($_ =~ /sshd\[\d+\]:\s+Failed password for (.+?) from (.+?) port/i)
        {
        	my $user = $1;
                my $host = $2;
                
                $user = "unknown" unless $user =~ /\w/;
                $host = "unknown" unless $host =~ /\w/;

        	print "echo 'Secure shell login for user $user from host $host failed!' | $festival --tts\n" if $debug;
        	system("echo 'Secure shell login for user $user from host $host failed!' | $festival --tts");

                $counter{$user}++;
        }

	# Successfull login
	elsif(($_ =~ /session opened for user (.+?) by/i) && ($_ !~ /CRON\[\d+\]/i))
        {
        	if($ssh_login)
                {
                	$ssh_login = 0;
                }
                else
                {
                     	my $user = $1;
                        $user = "unknown" unless $user =~ /\w/;

        	        print "echo 'User $user logged in' | $festival --tts\n" if $debug;
        	        system("echo 'User $user logged in' | $festival --tts");

                        $counter{$user} = 0;
                }
        }

        # Failed login
        elsif(($_ =~ /FAILED LOGIN (\(\d\)) on `(.+?)' FOR `(.+?)'/i) && ($_ !~ /CRON\[\d+\]/i))
        {
        	my $number = $1;
        	my $term = join(" ", split(//,$2)); # spaces for a better pronunciation
        	my $user = $3;

                $number = 1 unless $number =~ /\d/;
                $user = "unknown" unless $user =~ /\w/;
           
        	print "echo 'Failed login number $number for user $user on $term' | $festival --tts\n" if $debug;
        	system("echo 'Failed login number $number for user $user on $term' | $festival --tts");

                $counter{$user}++;
        }

        # Logout
        elsif(($_ =~ /session closed for user (.+)/i) && ($_ !~ /CRON\[\d+\]/i))
        {
        	my $user = $1;
                $user = "unknown" unless $user =~ /\w/;

        	print "echo 'User $user logged out' | $festival --tts\n" if $debug;
        	system("echo 'User $user logged out' | $festival --tts");
        }

        # su login
        elsif($_ =~ /\d\d\s(.+)\ssu\[\d+]: pam_unix(su:session): session opened for user (.+) by/i)
        {
        	system("echo 'User $2 logged in!' | $festival --tts");        
                $counter{$user} = 0;
        }

        # su login
        elsif($_ =~ /\d\d\s(.+)\ssu\[\d+]: pam_unix(su:session): session closed for user (.+) by/i)
        {
        	system("echo 'User $2 logged out!' | $festival --tts");        
        }

        # Failed su
        elsif($_ =~ /authentication failure\;.+?ruser\=(.+?)\s+.+?\s+user\=(.+)/i)
        {
        	my $ruser = $1;
        	my $user = $2;
                $ruser = "unknown" unless $ruser =~ /\w/;
                $user = "unknown" unless $user =~ /\w/;

        	print "echo 'Attempt of user $ruser to get user $user failed!' | $festival --tts\n" if $debug;
        	system("echo 'Attempt of user $ruser to get user $user failed!' | $festival --tts");        

                $counter{$user}++;
        }

        # Attempted login (e.g. proftpd root login)
        elsif($_ =~ /.+?\[\d+\]\:\s+(.+?)\s\(.+?\)\s\-\s.*?\:\s*(.+?) login attempt/i)
        {
                my $host = $1;
                my $user = $2;

                $host = "unknown" unless $host =~ /\w/;
                $user = "unknown" unless $user =~ /\w/;

        	print "echo 'User $user tried to login from host $host' | $festival --tts\n" if $debug;
        	system("echo 'User $user tried to login from host $host' | $festival --tts");                
        }

        # Failed login e.g. proftp
        elsif($_ =~ /.+?\[\d+\]\:\s+(.+?)\s\(.+?\)\s\-\sUSER\s+(.+?)\s+\(Login failed\)/i)
        {
                my $host = $1;
                my $user = $2;

                $host = "unknown" unless $host =~ /\w/;
                $user = "unknown" unless $user =~ /\w/;

        	print "echo 'Login for user $user from host $host failed!' | $festival --tts\n" if $debug;
        	system("echo 'Login for user $user from host $host failed!' | $festival --tts");                

                $counter{$user}++;
        }

        foreach my $user (keys %counter)
        {
           if($counter{$user} >= 3)
           {
        	print "echo 'Too many login attempts! Shutting down system.' | $festival --tts\n" if $debug;
        	system("echo 'Too many login attempts! Shutting down system!' | $festival --tts");                
                system("halt -p");
           }
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