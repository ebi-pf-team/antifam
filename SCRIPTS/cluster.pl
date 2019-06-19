#! /usr/local/bin/perl

# A script to do single linkage clustering.

use lib '/warehouse/pfam01/antifam/SCRIPTS/';
use Cluster;
use ClusterSet;
use strict;
use Getopt::Long;

my ($thresh,$data_file,$fasta_file);

&GetOptions('d=s'     => \$data_file,
            't=i'     => \$thresh,
	   );

if (! $data_file || ! $thresh){&help;}

#____________________________________________________________________
# Title    : help
# Usage    : &help
#____________________________________________________________________
sub help {
    print STDERR << "EOF";
$0 -d <data file> -t <threshold>

OPTIONAL ARGUMENTS

This program clusters data using the single linkage clustering 
algorithm.  Data is in MSPcrunch style format

name1 score name2

Threshold gives the blast score above which objects are clustered.

EOF
exit 0;
}

my $debug=0;                          # set to 1 to get voluminous output
my $set = new ClusterSet();

open (FH, "$data_file") or die "Cannot open $data_file";
while(<FH>){
    if (/^(\S+)\s+(\S+)\s+(\S+)/){
	my $score=$2;
	my $id1=$1;
	my $id2=$3;

	if ($debug){
	    print $_;
	}

	my $cluster;
	if ($score > $thresh){ # Linked
	    $set->single_link($id1,$id2);
	}
    } else {
	warn "Unrecognised line [$_]\n";
    }
}
close (FH);

$set->write();


__END__
