#!/usr/bin/perl 
## ./split.pl  -k 1  -o jnk  test.grib2

use strict;
use File::Basename;
use File::Copy;
use Net::FTP;
use Date::Parse;
use List::Util qw[min max];
use File::stat;

sub Usage {
    print STDERR "
Usage: split.pl -o <dir> -k <cnt> <GRIBFILES>

Splits grib-file into single message files.

\n";
    exit 1;
}
my $keep;
my $outdir="./";
while ($_ = $ARGV[0],/^-./) {
    shift;
    my $pattern = $_;
    if ($pattern =~ /^-k$/) {$keep = shift @ARGV; next;}
    if ($pattern =~ /^-o$/) {$outdir = shift @ARGV; next;}
    &Usage;
}


my $home = $ENV{HOME};

foreach my $arg (@ARGV) {
    if ($arg =~ m/^(.*)\/([^\/]*)\.(grib.*)$/) {
	process($1,$2,$3,$outdir);
    } elsif ($arg =~ m/^([^\/]*)\.(grib.*)$/) {
	process(".",$1,$2,$outdir);
    };
};

sub process {
    my $dir=shift;
    my $name=shift;
    my $suffix=shift;
    my $outdir=shift;
    # read file into string
    my $cnt=0;
    my $oh;
    my $pos=0;
    my $chunk=500;
    my @buff=[];
    my $oldpp;
    use autodie;
    my $file="${dir}/${name}.${suffix}";
    print("Opening input  $file\n");
    open my $fh, '<:raw', $file || die("Unable to open $file");
    while (my $bytes_read = read $fh, my $bytes, $chunk) {
	###die "Got $bytes_read but expected $chunk" unless $bytes_read == $chunk;
	##my ($magic) = unpack 'a128', $bytes;
	undef $oldpp;
	for (my $pp=0;$pp<$bytes_read;$pp++) {
	    my $byte=substr($bytes,$pp,1);
	    if ($pos==0 && $byte eq "G") {
		$buff[$pos]=$byte;
		$pos++;
	    } elsif ($pos==1 && $byte eq "R") {
		$buff[$pos]=$byte;
		$pos++;
	    } elsif ($pos==2 && $byte eq "I") {
		$buff[$pos]=$byte;
		$pos++;
	    } elsif ($pos==3 && $byte eq "B") {
		$buff[$pos]=$byte;
		#print("Found new GRIB message...\n");
		if ($oh) {close($oh);undef $oh;};
		$cnt++;
		if (! $keep or $keep==$cnt) {
		    my $filename="${outdir}/${name}_${cnt}.${suffix}";
		    print("Opening output $filename\n");
		    open $oh, '>:raw', $filename or die;
		}
		$pos++;
		# open and reset pos...
	    } elsif ($pos>0) {
		if ($oh) {
		    for (my $ii=0;$ii<$pos;$ii++) {
			print $oh $buff[$ii];
		    }
		    print $oh $byte;
		}
		$pos=0; # reset counter
	    } elsif ($oh) {
		print $oh $byte;
	    }
	}
    }
    if ($oh) {close($oh);}
    if ($fh) {close($fh);}
    
    # split on GRIB
    # write elements to file
}
#==============================================
#  End task.
#==============================================

