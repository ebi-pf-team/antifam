#! /usr/bin/perl

use strict;
use warnings;
use Cwd;
use Config::General;

# Scripts to build a release of AntiFam

my $antifam_root='/nfs/production/agb/antifam';

my $release=shift @ARGV;

if (! $release){
  die "Please add release number to run this program!";
}
my $old_release;
if($release =~ /(\d+)\.0/) {
  my $x=$1;
  $x--;
  $old_release = $x.".0"; 
}
else {
  die "Release is in the wrong format, it should be in the format X.0 (eg 5.0)\n";
}

#Read Pfam config to get uniprot location
my $conf = read_pfam_config();
my $uniprot = $conf->{uniprot}->{location}."/uniprot";

my $dir = getcwd

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

#populate the arrays with the file names for the entries which will go in each tax-specific set
foreach my $file (sort @list){
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
    }
  }
  close(FILE);
}

#catenate seed files for all of antifam
my $num_entries=0;
print STDERR "Catenating seed files\n";
foreach my $file (sort @list){
  if ($file =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$file >> $release_dir/AntiFam.seed");
    $num_entries++;
  }
}

#catenate seed files for tax-specific sets
my $num_eukaryota=0;
print STDERR "Catenating eukaryote seed files\n";
foreach my $entry (sort @eukaryota_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Eukaryota.seed");
    $num_eukaryota++;
  }
}
my $num_bacteria=0;
print STDERR "Catenating bacteria seed files\n";
foreach my $entry (sort @bacteria_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Bacteria.seed");
    $num_bacteria++;
  }
}

my $num_archaea=0;
print STDERR "Catenating archaea seed files\n";
foreach my $entry (sort @archaea_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Archaea.seed");
    $num_archaea++;
  }
}

my $num_virus=0;
print STDERR "Catenating virus seed files\n";
foreach my $entry (sort @virus_set){
  if ($entry =~ /(.*\.seed$)/){
    system ("cat $antifam_root/ENTRIES/$entry >> $release_dir/AntiFam_Virus.seed");
    $num_virus++;
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

# Make binary HMM libraries
system ("hmmpress AntiFam.hmm");
system ("hmmpress AntiFam_Eukaryota.hmm");
system ("hmmpress AntiFam_Bacteria.hmm");
system ("hmmpress AntiFam_Archaea.hmm");
system ("hmmpress AntiFam_Virus.hmm");

# Copy relnotes to dir and add the number of entries to it
my $old_relnotes = "$antifam_root/RELEASES/$old_release/relnotes";
unless(-s $old_relnotes) {
  die "Could not locate relnotes files from the last release, expecting to find it in here: $antifam_root/RELEASES/$old_release/relnotes\n";
}
my $new_relnotes = "$release_dir/relnotes";
open(NEWRN, ">$new_relnotes") or die "Couldn't open fh to $new_relnotes, $!";
open(OLDRN, $old_relnotes) or die "Couldn't open fh to $old_relnotes, $!";
my $added_line;
while(<OLDRN>) {
  if(/^\s+$old_release\s+\d+/) {
    print NEWRN $_;
    my $num = sprintf ('%8s', $num_entries);
    print NEWRN "   $release $num\n";
    $added_line=1;
  }
  else {
    print NEWRN $_;
  }
}
close OLDRN;
if($added_line) {
  print STDERR "Please check the number of entries for release $release has been added correctly to relnotes\n";
}
else {
  die "Unable to add number of entries for this release to the relnotes\n";
}

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
print STDERR "Tar up release files\n";
system("tar -cvf AntiFam_$release.tar AntiFam.seed AntiFam_Eukaryota.seed AntiFam_Bacteria.seed AntiFam_Archaea.seed AntiFam_Virus.seed AntiFam.hmm AntiFam_Eukaryota.hmm AntiFam_Bacteria.hmm AntiFam_Archaea.hmm AntiFam_Virus.hmm relnotes version");
if (-e "AntiFam_$release.tar"){
  system("gzip AntiFam_$release.tar");
} else {
  die "Failed to make tar file";
}

#Submit the hmmsearch jobs against uniprot to the farm
chdir($dir) or die "Couldn't chdir $dir, $!"; 
my $options = "-q ".$conf->{farm}->{lsf}->{queue}." -M 2000 -R \"rusage[mem=2000]\"";

foreach my $type (qw/All/) {
  print STDERR "Submitting $type hmmsearch to farm\n";
  my $log_file = "$type.log";

  my ($hmm_file, $output_file);
  if($type eq "All") {
    $hmm_file = "AntiFam.hmm";
    $output_file = "Antifam.output";
  }
  else {
    $hmm_file = "AntiFam_"."$type.hmm";
    $output_file = "Antifam_"."$type.output";
  }

  system("bsub $options -o $log_file -J$type 'hmmsearch --noali --cpu 4 --cut_ga $release_dir/$hmm_file $uniprot > $output_file'");
}


sub read_pfam_config {

  unless($ENV{PFAM_CONFIG} and -s $ENV{PFAM_CONFIG}) {
    die "Can't locate the Pfam config\n";
  }

  my ($conf) = $ENV{PFAM_CONFIG} =~ m/([\d\w\/\-\.]+)/;
  my $c      = new Config::General($conf);
  my %ac     = $c->getall;

  return(\%ac);
}
