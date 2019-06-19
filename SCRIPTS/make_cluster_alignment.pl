#! /usr/local/bin/perl -w

# A script to make alignments from Alex's cluster XML format
use lib '/warehouse/pfam01/antifam/SCRIPTS/';
use Cluster;
use ClusterSet;
use strict;

sub help {
    print "Usage: $0 <fasta file> <cluster file> <optional lsf queue>\n";
    exit (0);
}


my $fasta       = shift @ARGV;
my $clusterfile = shift @ARGV;
my $queue       = shift @ARGV;

if (! $fasta or ! $clusterfile){
    &help;
}


# Get sequences
my %hash;
my $id;
open (F, "$fasta")||die "Cannot open $fasta file";
while(<F>){
    if (/^>(\S+)/){
      $id=$1;
    } else {
      chomp;
      $hash{$id}.=$_;
    }
}
close (F);

open(F, "$clusterfile")||die "Can't open $clusterfile\n";
my $set=new ClusterSet;
$set->read(\*F);

# Make hash of cluster numbers to reference
my %cluster_hash;
warn "SET $set\n";
foreach my $cluster ($set->each()){
  my $number=$cluster->number;
  print "$number $cluster\n";
  $cluster_hash{$number}=$cluster;

  open(FASTA, "> $number.fa")||die "Can't write to $number.fa";
  foreach my $protein ($cluster->each()){
    print FASTA ">$protein\n$hash{$protein}\n";
  }  
  close (FASTA);

  my $command="create_alignment.pl -fa $number.fa -m > $number.ali";

  # Add queue syntax if needed
  if ($queue){
    $command="bsub -q $queue \'$command\'";
  }

  print "Aligning cluster $number with command\n$command\n";
  system("$command");

}

__END__
