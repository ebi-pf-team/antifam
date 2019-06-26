#! /usr/local/bin/perl -w

use strict;
# Find overlaps of CDS in EMBL file

my $acc="CP002815";
#my $acc="AATQ01000041";
# get entry

my $all=1;

my $min_size='50';
my $embl_dir="/lustre/scratch101/sanger/agb/";

my @list;
if ($all){
    opendir (DIR, "$embl_dir")||die "Couldn't open directory\n";
    @list=readdir(DIR);
    closedir(DIR);
    
    # Remove . and .. directories 
    shift  @list;
    shift  @list;

    my @list2;
    foreach my $element (@list){
	if ($element=~ /^(.*\.dat)/){
	    push (@list2,$1);
	}
    }

    @list=@list2;
} else {
    @list=$acc;
}


foreach my $file (@list){
    my ($start,$end,$old_start,$old_end,$old_line,$line);
    my ($embl_id,$type,$revcomp,$uniprot_id,$strand,$old_strand,$length,$frame,$old_frame);
    if ($all){
#	open (FH, "pfetch -F $file |") or die "cannot open embl acc $file";
	open (FH, "$embl_dir/$file") or die "cannot open embl file $file";
    } else {
	open (FH, "pfetch -F $acc |") or die "cannot open embl acc $acc";
    }
    while(<FH>){
	if (/^ID   (\S+);/){
	    $embl_id=$1; 
	    print STDERR "EMBL_ID: $embl_id\n";
	    # Its a new EMBL entry, better initialise stuff!
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
	
	if (/^FT\s+(CDS|tRNA|rRNA)\s+(complement)?\(?(\d+)\.\.(\d+)\)?/){
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
	    $line="$embl_id\t$type\t$strand\t$frame\t$uniprot_id\t$start\t$end\t$length";
	    
	    if ($old_end>$start){
		my $size=$old_end-$start+1;		
		if ($size>$min_size){
		    unless ($old_strand eq $strand and $old_frame eq $frame){
			print "\n",$old_line,"\t$size\n";
			print $line,"\t$size\n";
		    } else {
			warn "Strand and Frame appear to be the same [$old_strand] [$strand] [$old_frame] [$frame]";
		    }
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
}
