#! /usr/local/bin/perl

use strict;
use warnings;

# Scripts to build a release of AntiFam

my $antifam_root='/nfs/production/xfam/antifam';
my $seqdb='/nfs/production/xfam/pfam/data/pfamseq31/pfamseq';

my $release=shift @ARGV;

if (! $release){
  die "Please add release number to run this program!";
}

print STDERR "Creating new AntiFam release $release\n";
my $release_dir="$antifam_root/RELEASES/$release";

if (! -d $release_dir){
  system("mkdir $release_dir");
} else {
  die "$release_dir already exists. Will not try and overwrite an existing release!";
}

# Get all seed files;
opendir (DIR, "$antifam_root/ENTRIES")||die "Couldn't open directory $antifam_root/ENTRIES\n";
my @list=readdir(DIR);
closedir(DIR);

# Remove . and .. directories 
shift  @list;
shift  @list;

if (-e "$release_dir/AntiFam.seed"){
  die "You appear to have already made $release_dir/AntiFam.seed";
}

#set up arrays for each tax-specific set to go into
my @bacteria_set;
my @eukaryota_set;
my @virus_set;
my @archaea_set;
my @unknown_set;

#populate the arrays with the file names for the entries which will go in each tax-specific set
foreach my $file (@list){
  open (FILE, "$antifam_root/ENTRIES/$file") or die "cannot open $!\n";
  while(<FILE>){
    if (/^\#=GF\sTX.+Eukaryota.+$/){
      push (@eukaryota_set, $file);
    } if (/^\#=GF\sTX.+Bacteria.+$/){
      push (@bacteria_set, $file);
    } if (/^\#=GF\sTX.+Archaea.+$/){
      push (@archaea_set, $file);
    } if (/^\#=GF\sTX.+Virus.+$/){
      push (@virus_set, $file);
    } if (/^\#=GF\sTX.+unidentified.+$/){
      push (@unknown_set, $file);
    }
  }
  close(FILE);
}

#catenate seed files for all of antifam
my $num_entries=0;
print STDERR "Catenating seed files\n";
foreach my $file (@list){
  if ($file =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$file >> $release_dir/AntiFam.seed");
    $num_entries++;
  }
}

#catenate seed files for tax-specific sets
my $num_eukaryota=0;
print STDERR "Catenating eukaryote seed files\n";
foreach my $entry (@eukaryota_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Eukaryota.seed");
    $num_eukaryota++;
  }
}
my $num_bacteria=0;
print STDERR "Catenating bacteria seed files\n";
foreach my $entry (@bacteria_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Bacteria.seed");
    $num_bacteria++;
  }
}

my $num_archaea=0;
print STDERR "Catenating archaea seed files\n";
foreach my $entry (@archaea_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Archaea.seed");
    $num_archaea++;
  }
}

my $num_virus=0;
print STDERR "Catenating virus seed files\n";
foreach my $entry (@virus_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Virus.seed");
    $num_virus++;
  }
}

my $num_unidentified=0;
print STDERR "Catenating virus seed files\n";
foreach my $entry (@unknown_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Unidentified.seed");
    $num_unidentified++;
  }
}

# Should really strip out GA lines as these may be for previous HMMER releases!
chdir $release_dir;

# Make HMM libraries
print STDERR "Building HMM library, all entries\n";
system ("hmmbuild AntiFam.hmm AntiFam.seed");

print STDERR "Building HMM library, Eukaryota\n";
system ("hmmbuild AntiFam_Eukaryota.hmm AntiFam_Eukaryota.seed");

print STDERR "Building HMM library, Bacteria\n";
system ("hmmbuild AntiFam_Bacteria.hmm AntiFam_Bacteria.seed");

print STDERR "Building HMM library, Archaea\n";
system ("hmmbuild AntiFam_Archaea.hmm AntiFam_Archaea.seed");

print STDERR "Building HMM library, Virus\n";
system ("hmmbuild AntiFam_Virus.hmm AntiFam_Virus.seed");

print STDERR "Building HMM library, Unidentified\n";
system ("hmmbuild AntiFam_Unidentified.hmm AntiFam_Unidentified.seed");

# Make binary HMM libraries
system ("hmmpress AntiFam.hmm");
system ("hmmpress AntiFam_Eukaryota.hmm");
system ("hmmpress AntiFam_Bacteria.hmm");
system ("hmmpress AntiFam_Archaea.hmm");
system ("hmmpress AntiFam_Virus.hmm");
system ("hmmpress AntiFam_Unidentified.hmm");

# Copy relnotes to dir
print STDERR "Copying relnotes file to release. Please make sure it is up to date!\n";
system ("cp $antifam_root/relnotes $release_dir");

# Create version file
my $date;
open (DATE, 'date |') or die "Cannot run date command";
while(<DATE>){
  $date=$_;
}
close DATE;
chomp $date;
open (FH, "> version") or die "Cannot write to file version";
print FH "AntiFam release: $release\nAntiFam families: $num_entries\nDate: $date\n";
close FH;

# Make tar file - putting all hmms/seeds in one. Could later split to do tax specific tars
print STDERR "Tar up release files:\n";
system("tar -cvf AntiFam_$release.tar AntiFam.seed AntiFam_Eukaryota.seed AntiFam_Bacteria.seed AntiFam_Archaea.seed AntiFam_Virus.seed AntiFam_Unidentified.seed AntiFam.hmm AntiFam_Eukaryota.hmm AntiFam_Bacteria.hmm AntiFam_Archaea.hmm AntiFam_Virus.hmm AntiFam_Unidentified.hmm relnotes version");
if (-e "AntiFam_$release.tar"){
  system("gzip AntiFam_$release.tar");
} else {
  die "Failed to make tar file";
}


