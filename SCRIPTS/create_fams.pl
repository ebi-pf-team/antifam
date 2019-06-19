#! /usr/local/bin/perl

# This script takes a nucleotide alignment and does the following:
#  1) Translates peptides in 6 frames
#  2) clusters peptides with blast
#  3) Makes alignments
#  4) Builds family for each cluster
#

my $ali=shift @ARGV;
my $thresh=shift @ARGV;

if (! $thresh){$thresh=80;}

system("esl-weight -f --idf 0.9 $ali > tmp");
system("esl-reformat fasta tmp > tmp2");
system("/software/rfam/src/infernal-0.81/squid/translate -q tmp2 > $ali.fa");

if (! -s "$ali.fa"){
    die "Failed to create peptide fasta sequences from alignment $ali";
}

print STDERR "Formatting Blast database\n";
system("formatdb -p T -i $ali.fa");
print STDERR "Running Blast\n";
system("blastall -d $ali.fa -p blastp -i $ali.fa -m 8 -o $ali.bla");
print STDERR "Formatting output\n";

open (FH, "$ali.bla") or die "Cannot open $ali.bla";
open (OUT, "> $ali.dat") or die "Cannot write $ali.dat";
while(<FH>){
    my @a=split;
    print OUT "$a[0] $a[11] $a[1]\n";
}
close FH;
close OUT;

print STDERR "Clustering blast output\n";
system("/warehouse/pfam01/antifam/SCRIPTS/cluster.pl -d $ali.dat -t $thresh > $ali.clu");
print STDERR "Making sequence alignments\n";
system("/warehouse/pfam01/antifam/SCRIPT/make_cluster_alignment.pl $ali.fa $ali.clu");

print STDERR "Making families\n";
my $dir=".";
opendir (DIR, "$dir")||die "Couldn't open directory\n";
my @list=readdir(DIR);
closedir(DIR);

# Remove . and .. directories 
shift  @list;
shift  @list;

foreach my $file (@list){
    if ($file =~ /^(\d+)\.ali$/){
	my $n=$1;
	print STDERR "Working on cluster $n\n";
	if (! -d $n){
	    system("mkdir $n");
	}
	system("mv $n.ali $n/SEED");
	system("mv $n.fa $n/");
	chdir "$n";
	if (-e "SEED"){
	    system("pfbuild -withpfmake");
	} else {
	    system ("pwd");
	    die "Couldn't find SEED file in $n";
	}
	chdir "..";
    }
}
