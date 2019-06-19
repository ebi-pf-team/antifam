#! /usr/local/bin/perl -w

use strict;
use Getopt::Long;

# This program can be run across INSDC files to look for genes that are overlapping. Spurious
# ORFs are often overlapping and come from poor gene prediction pipelines.  Short overlaps of
# ORFs are tolerated, but long ones are less likely. This script is designed with prokaryotic
# genes in mind.
#
# This script will ignore any eukaryotic entries because deadling with exon/intron structure
# is too complex.

# To do
#
# 1) Add code to allow it to restart from where it left off. Currently it does not record
#    entries it looked at that did not match. Perhaps generate a file with these in.



sub help {
    print STDERR <<"EOF";
$0 USAGE AND HELP

This script is used to identify overlapping ORFs in INSDC files.

Usage: $0 -output <filename> -acc <INSDC identifier> || -all

Options: -acc <file>           Run program on a specific entry, e.g. CP002815
         -all                  Run program on all WGS entries in ENA. Note this catenates entries from project into single file
         -output <file>        Must provide output file name
EOF
}

my ($acc,$all,$min_overlap,$output,$total_translation,$total_overlap);
&GetOptions('all'  => \$all, # Loop over all EMBL WGS accessions
            'acc=s' => \$acc,
	    'min_overlap=i' => \$min_overlap,
	    'output=s' => \$output);

if (! $all and ! $acc){
    help();
}

if (! $min_overlap){  # Minimum size of nucleotide overlap to report
    $min_overlap='50'
};

my $embl_dir="/ebi/ftp/pub/databases/ena/wgs/public/";
if (-s $output){
    warn "Output file $output already exists. Will append results to it.\n";
}

open (OUTPUT, ">> $output") or die "Cannot write to $output";

# Print header line
print OUTPUT "EMBL_id\tType\tStrand\tFrame\tUniprot_id\tStart\tEnd\tLength(AA)\tType\tStrand\tFrame\tUniprot_id\tStart\tEnd\tLength(AA)\tOverlap(NT)\n";

# Read in id.log to see what entries to ignore
my %ignore;
if ($all){
    if (-e "$output.id.log"){
	open (LOG, "$output.id.log") or warn "Cannot open $output.id.log";
	while(<LOG>){
	    if (/(.*)/){
		$ignore{$1}=1;
	    }
	}
	close LOG;
    }
}

my @list;
if ($all){
    opendir (DIR, "$embl_dir")||die "Couldn't open directory $embl_dir\n";
    @list=readdir(DIR);
    closedir(DIR);
    
    # Remove . and .. directories 
    shift  @list;
    shift  @list;

    my @list2;
    foreach my $element (@list){
	opendir (DIR, "$embl_dir/$element")||die "Couldn't open directory $embl_dir/$element\n";
	@list2=readdir(DIR);
	closedir(DIR);
	
	foreach my $file (@list2){
	    if ($file=~ /^.*\.dat.gz/){
		process("$embl_dir/$element/$file");
		
	    }
	}
    }
} else {
    system ("pfetch -F $acc > $$.tmp") and die "cannot open embl acc $acc";
    process("$$.tmp");
}



sub process {
    my $file=shift @_;
    my ($start,$end,$old_start,$old_end,$old_line,$line);
    my ($embl_id,$type,$revcomp,$uniprot_id,$strand,$old_strand,$length,$frame,$old_frame);
    my ($num_overlaps,$num_translation);
    my $species;

    my $project;
    if ($file =~ /.*\/(.*)\.dat\.gz/){
	open (FH, "gunzip -c $file |") or die "cannot open embl file $file";
	$project=$1;
    } else {
	open (FH, "cat $file |") or die "cannot open embl file $file";
    }
    while(<FH>){
	# Check taxonomy
	if (/^OC.*Eukaryot/){
	    print STDERR "Ignoring $file which is Eukaryotic\n";
	    return 0;
	}

	if (/^OS\s+(.*)/){
	    $species=$1;
	}

	if (/^ID   (\S+);/){
	    $embl_id=$1; 

	    if ($ignore{$embl_id}){
		print STDERR "Skipping $embl_id\n";
		return 0;
	    }
	    if ($all){
		system ("echo $embl_id >> $output.id.log");
	    }

	    if (! $project){
		$project=$embl_id;
	    }
	    # Its a new EMBL entry, better initialise stuff! Not sure I really need this anymore
	    undef $start;
	    undef $end;
	    undef $old_start;
	    undef $old_end;
	    undef $old_line;
	    undef $line;
	    undef $type;
	    undef $revcomp;
	    undef $uniprot_id;
	    undef $strand;
	    undef $old_strand;
	    undef $length;
	    undef $frame;
	    undef $old_frame;    
	}
	
	if (/FT\s+\/db_xref=\"UniProtKB\/.*:(\S+)\"/){$uniprot_id=$1;}
	
	if (/^FT\s+(CDS|tRNA|rRNA)\s+(complement)?\(?<?(\d+)\.\.>?(\d+)\)?/){
	    $old_start=$start;
	    $old_end=$end;
	    $type=$1;
	    $revcomp=$2;
	    $start=$3;
	    $end=$4;
	    $frame=$start % 3;
	    
	    $length=($end-$start+1)/3;
	    
	    if (defined $revcomp and $revcomp eq "complement"){
		$strand='-';
	    } else {
		$strand='+';
	    }
	}
	
	# Use this as a trigger to print out stuff and reset parameters
	if (/^FT\s+\/translation=/){
	    $num_translation++;
	    $total_translation++;
	    if (! $uniprot_id){$uniprot_id='NA'}
	    if (! $type){
		warn "No type for $embl_id. Possibly eukaryotic entry\n";
	    }
	    $line="$type\t$strand\t$frame\t$uniprot_id\t$start\t$end\t$length";
	    
	    if (defined $old_start and $old_end>$start){
		#my $size=$old_end-$start+1; # This is not correct if one ORF is nested within the other!		
		my $size=residue_overlap($old_start,$old_end,$start,$end);
		if ($size>$min_overlap){
		    $total_overlap++;
		    $num_overlaps++;

		    if (! defined $old_strand){
			warn "old_strand not defined for $project $embl_id. Probably previous gene did not have a translation! Happens in NCBI PGAP.\n";
		    }

		    if (! defined $old_line){
			warn "old_line not defined for $line\n";
		    }
		    print OUTPUT $embl_id,"\t",$old_line,"\t",$line,"\t",$size,"\n";
		}
	    }
	    
	    $old_line=$line;
	    $old_frame=$frame;
	    $old_strand=$strand;	    

	    # Reset UniProt acc
	    $uniprot_id="";
	}
    }
    close FH;

    if ($num_overlaps){
	print OUTPUT "# $project: Fraction of overlapping ORFs: ",$num_overlaps/$num_translation," $num_overlaps out of $num_translation for $species\n";
	print OUTPUT "## Long overlaps: $total_overlap Translations: $total_translation Percentage: ",100*$total_overlap/$total_translation,"\n";
    }

}


###################
# residue_overlap #
###################

=head2 residue_overlap

Method to check if two regions overlap and returns number of overlapping residues

    $num_overlap_residues=residue_overlap($start1, $end1,$start2, $end2);

=cut

sub residue_overlap {
    my ($start1,$end1,$start2,$end2)=@_;

    # shortcircuits test
    if ($end1<$start2 or $end2<$start1){
        return 0;
    }

    # This method requires the midpoint of one region to lie within the other
    my $mid1=($start1+$end1)/2;
    my $mid2=($start2+$end2)/2;
    
    my $overlap=0;
    if ($start1<$start2 and $end1<$end2){
        $overlap=$end1-$start2+1;
    } elsif ($start1>=$start2 and $end1<=$end2){
        $overlap=$end1-$start1+1;
    } elsif ($start1>=$start2 and $end1>=$end2){
        $overlap=$end2-$start1+1;
    } elsif ($start2>$start1 and $end2<$end1){
        $overlap=$end2-$start2+1;
    }

    return $overlap;
}
