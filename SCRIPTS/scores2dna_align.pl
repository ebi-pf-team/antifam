#! /software/bin/perl

use strict;
use warnings;
use File::Copy;
use Getopt::Long;

#script to open a pfam scores file and return an alignment of the underlying DNA
#requires /warehouse/pfam01/antifam/SCRIPTS/protein2dna.pl

my ($method, $mafft, $muscle, $clustalw, $musclep, $tcoffee, $full, $help);

#get options - alignment method, full (default is domain only)
&GetOptions('m!' => \$mafft,
	    'mu!' => \$muscle,
	    'cl!' => \$clustalw,
	    'mup!' => \$musclep,
	    't!' => \$tcoffee,
	    'F!' => \$full,
	    'h' => \$help,
	    );

if ($help){
    &help;
}

#if no alignment method is specified print error message plus help

if (! $mafft and ! $muscle and ! $clustalw and $musclep and ! $tcoffee){
    print "Please specify an alignment method\n\n";
    &help;
}

#read in Pfam scores file
open (SCORES, "scores") or die "can't find the file $!\n";
my @scores=<SCORES>;
close (SCORES) or die "can't close file $!\n";

#If full is selected, fetch the DNA sequence encoding the whole protein. Otherwise, 
#fetch the sequence encoding just the alignment region in the scores file.
if ($full){

foreach my $score (@scores) {
	if ($score=~/([A-Z]\w{5})\./ig){
	    print "fetching DNA sequence for $1: ";
	    system ("/warehouse/pfam01/antifam/SCRIPTS/protein2dna.pl $1 >> DNAseq.fa");
	}
    }
}else{

foreach my $score (@scores) {
	if ($score=~/([A-Z]\w{5})\.\d+\/(\d+)\-(\d+)/ig){
	    print "fetching DNA sequence for $1: start $2 end $3: ";
	    system ("/warehouse/pfam01/antifam/SCRIPTS/protein2dna.pl $1 -s $2 -e $3 >> DNAseq.fa");
	}
    }
}

#set alignment method
if ($mafft) {
    $method="m";
    print "\n\nALIGNING WITH MAFFT\n\n";
}
if ($muscle){
    $method="mu";
    print "\n\nALIGNING WITH MUSCLE\n\n";
}
if ($clustalw){
    $method="cl";
    print "\n\nALIGNING WITH CLUSTALW\n\n";
}
if ($musclep){
    $method="mup";
    print "\n\nALIGNING WITH MUSCLE PROGRESSIVE-ALIGNMENT METHODS\n\n";
}
if ($tcoffee){
    $method="t";
    print "\n\nALIGNING WITH T-COFFEE - this may take a long time......\n\n";
}

#Create alignment, and launch in belvu

system ("create_alignment.pl -fasta DNAseq.fa -$method > DNAalign");
system ("belvu DNAalign &");
unlink ("DNAseq.fa");

sub help {
print STDERR <<"EOF";
This script creates an DNA alignment from a Pfam scores file. 
Options:
-F   (Optional) aligns the DNA sequence of the whole proteins 
     (the default is to align only the sequences corresponding 
     to the region in the scores file)

Alignment method (one is required):
-m    MAFFT	 
-mu   Muscle
-cl   ClustalW	 
-mup  Muscle progressive-alignment methods (quicker, less accurate) 
-t    T-coffee (WARNING - THIS IS VERY SLOW!!)

EOF
    exit 1;
}
