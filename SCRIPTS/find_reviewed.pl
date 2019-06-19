#! /usr/local/bin/perl

# Scripts to find which Antifam matched proteins in UNiProt are from the reviewed section
# Expects to be given a file with a list of uniprot accs

my $file=shift @ARGV;

open (FH, $file) or die "cannot open $file";
while(<FH>){
    if (/^(\S+)/){
	my $acc=$1;
	# print STDERR "Looking at $1\n";
	open (PFETCH, "pfetch -F $acc |") or warn "cannot pfetch $acc";
	while (<PFETCH>){
	    if (/^ID.*Reviewed;/){
		print "$acc in reviewed section of UniProtKB\n";
	    }

	}
	close PFETCH;


    } else {
	die "unrecognised line [$_]";
    }

}
close FH;
