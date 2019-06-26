#! /usr/local/bin/perl -w

use strict;

# Script to list potential spurious Pfam families

# The file below is created by running the script find_overlap.pl
my $data_file=shift @ARGV;

# Read into hash
print STDERR "Reading overlap data in\n";
my %protein;
open (FH, "$data_file") or die "Cannot open data file $data_file";
while(<FH>){
    if (/^\S+\s+\S+\s+[+-]\s+\d\s+(\S{6})\s+\d+\s+\d+\s+\d+\s+\d+/){
	$protein{$1}=1;
    } else {
	# No UniProt acc found!
    }

}
close FH;


print STDERR "Processing Pfam flatfile\n";
# Pfam flatfile
my $pfam_file="/warehouse/pfam01/pfam/production/archive/Pfam/RELEASES/25.0/Pfam-A.full";

# Loop over flatfile and record number of overlapping proteins per family
# Also record total number of proteins for that family

open (FH, "$pfam_file") or die "cannot open $pfam_file";
my ($pfam_acc,%fam_protein,$total,$total_overlap);
my %processed;
while(<FH>){
    if (/\#=GF AC   (PF\d{5}).\d+/){
	$pfam_acc=$1;
	if ($processed{$pfam_acc}){
	    die "You've already looked at $pfam_acc!";
	}
	$processed{$pfam_acc}=1;
	$total=0;
	$total_overlap=0;
	undef %fam_protein;
    } elsif(/\#=GS \S+\/\d+-\d+\s+AC\s+(\S{6})\.\d+/){
	$fam_protein{$1}=1;
	#print "Processing $1\n";
    } elsif (/^\/\//){
	# Reached end of family now do counting

	my $protein_string;

	foreach my $element (keys %fam_protein){
	    $total++;

	    if ($protein{$element}){
		$total_overlap++;
		$protein_string.="$element;";
	    }
	}

	my $fraction;
	if ($total){
	    $fraction=$total_overlap/$total;
	} else {
	    warn "No total proteins for $pfam_acc :(\n";
	    $fraction="NA";
	}
	# Now print out stats
	print "$pfam_acc\t$total\t$total_overlap\t$fraction\t$protein_string\n";

    }
}
close FH;





