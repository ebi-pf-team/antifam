#!/usr/bin/env perl
#
#Script to count number of uniprot matches to different Antifam HMM files
#Run this after the hmmsearch jobs submitted in build_release.pl have
#finished running. It needs to be run in the same dir as the output from 
#the hmmsearch jobs.

use strict;
use warnings;
use Getopt::Long;

my $release_dir;
GetOptions('release_dir=s' => \$release_dir);

unless($release_dir and -s $release_dir) {
  die "Need to specify the release dir on the command line.\nE.g. $0 -release_dir /nfs/production/xfam/antifam/RELEASES/5.0\n";
}

open(OUTFILE, ">$release_dir/uniprot.txt") or die "Couldn't open fh to $release_dir/uniprot.txt, $!";
foreach my $type (qw/All Archaea Bacteria Eukaryota Unidentified Virus/) {
  my $file;

  if($type eq "All") {
    $file = "Antifam.output";
  }
  else {
    $file = "Antifam_"."$type.output";
  }

  my $count=0;
  open(F, $file) or die "Couldn't open fh to $file, $!";
  while(<F>) {
    #   1e-59  208.2 100.2    1.7e+02   14.1   0.2   20.3 20  A0A0B2VL19.1  A0A0B2VL19_TOXCA Uncharacterized protein {ECO:0
    if(/^\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\.\d+/) {
      $count++;
    }
  }
  close F;
  printf OUTFILE "%-14s %5s\n", $type, $count;
}
close OUTFILE;

print STDERR "Results have been printed to: $release_dir/uniprot.txt\n";
