#! /usr/local/bin/perl -w

# Quick script to try and backtranslate protein sequence
# grabs EMBL entry to do this.

use strict;
use Getopt::Long;

my ($start,$end);

&GetOptions('s=i'  => \$start,
            'e=i' => \$end);

my $pid=shift @ARGV;

if (! $pid){
    &help;
}

sub help {
    print  << "EOF";
A program to try and fetch DNA sequence for a protein

Usage: $0 <uniprot acc> -s <start> -e <end>

Start and End parameters are optional.

EOF
    exit (0);

}


open (FH, "pfetch -F $pid |")or die "cannot pfetch $pid";
while(<FH>){
    if (/no match/){
	print STDERR "No match found for protein $pid\n";
    }
    if (/^DR   EMBL; (\S+);/){
	my $did=$1;

	get_dna($pid,$did,$start,$end);
	exit 0; # Note script only looks at first EMBL xref!
    }
}
close FH;



sub get_dna {
    my ($pid,$did,$start,$end)=@_;
	#print $pid,$did;
    my ($s,$e,$strand,$join);
    open (EMBL, "pfetch -F $did |")or die "cannot pfetch $did";
    while(<EMBL>){
	if (/no match/){
	    print STDERR "No match found for DNA record $did\n";
	}

	if (/^FT   CDS\s+join/){
	    $join=1;
	    #print STDERR "This EMBL file $did looks like it has intron/exon structure.  Too complex!!!\n";
	    # return;
	} elsif (/^FT   CDS\s+<?(\d+)\.\.>?(\d+)/){
	    #print;
	    $join=0;
	    $s=$1;
	    $e=$2;
	    $strand=1;
	} elsif (/^FT   CDS\s+complement\(<?(\d+)\.\.>?(\d+)\)/){
	    #print;
	    $join=0;
	    $s=$1;
	    $e=$2;
	    $strand=-1;
	} elsif (/\/db_xref=\"UniProtKB\/\S+:(\S+)\"/){
	    my $uniprotid=$1;
	    #print;
	    if ($pid eq $uniprotid){
		print STDERR "$pid\t$did\t$s\t$e\tSTRAND:$strand\n";

		if ($join){
		    print STDERR "This EMBL file $did looks like it has intron/exon structure.  Too complex!!!\n";
		    return;
		}

		# Can now get DNA sequence from protein
		my $command;
		if ($strand==1){
		    # if start and end are dinfined modify region to fetch
		    my ($s2,$e2);
		    if ($start){
			$s2=$s+($start-1)*3;
		    }
		    if ($end){
			$e2=$s-1+$end*3;
		    }
		    if ($s2){$s=$s2};
		    if ($e2){$e=$e2};

		    my $name=$did."/".$s."-".$e;
		    $command="pfetch -n $name -s $s -e $e $did";
		    open (DNA, "pfetch -n $name -a -s $s -e $e $did |") or die "cannot pfetch subsequence of $did";
		} elsif ($strand==-1){ # revcomp
		    my ($s2,$e2);
		    if ($start){
			$s2=$e+1-$end*3;
		    }
		    if ($end){
			$e2=$e-($start-1)*3;
		    }
		    if ($s2){$s=$s2};
		    if ($e2){$e=$e2};

		    my $name=$did."/".$s."-".$e;
		    $command="pfetch -n $name -s $s -e $e $did";
		    open (DNA, "pfetch -n $name -a -r -s $s -e $e $did |") or die "cannot pfetch subsequence of $did";
		}



		while(<DNA>){
		    if (/no match/){
			# Example of this error is G6EFT4
			print STDERR "No match found for DNA record $did - Switching off pfetch -a flag and retrying!\n";
			system($command);


		    } else {
			print;
		    }
		}
		close DNA;
		return; # This should speed up fetching particularly for big embl files 
	    }
	}
    }
    close EMBL;
}
