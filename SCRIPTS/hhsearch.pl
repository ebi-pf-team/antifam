#! /usr/local/bin/perl

my $dir=".";
opendir (DIR, "$dir")||die "Couldn't open directory\n";
my @list=readdir(DIR);
closedir(DIR);

# Remove . and .. directories 
shift  @list;
shift  @list;

foreach my $file (@list){
    if ($file =~ /^(\d+)$/ and -d $file){
	chdir "$file";
	print STDERR "hhmake -i HMM -o $file.hhm\n";
	system("hhmake -i HMM -o $file.hhm");

	# Need to rename HMM to something useful!
	open (FH, "$file.hhm") or die "cannot open $file.hhm"; 
	open (FH2, "> tmp") or die "cannot write tmp";
	while (<FH>){
	    if (/^NAME/){
		print FH2 "NAME  $file\n";
	    } else {print FH2;}
	}
	close FH;
	close FH2;
	system ("mv tmp $file.hhm");

	chdir "..";
    }
}

system ("cat */*.hhm > all.hhm");



foreach my $n(@list){
    if ($n =~ /^(\d+)$/ and -d $n){
	system("hhsearch -i $n/$n.hhm -d all.hhm -o $n/hhsearch.out");
    }
}
