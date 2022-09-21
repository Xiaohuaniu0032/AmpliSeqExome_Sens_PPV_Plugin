use strict;
use warnings;

my ($PPV_file,$outfile) = @ARGV;

open O, ">$outfile" or die;

open IN, "$PPV_file" or die;
while (<IN>){
	chomp;
	next if (/^$/);
	my @arr = split /\t/;
	my $sp = $arr[2] - 1; # start pos
	my $ep = $arr[2];     # end pos
	print O "$arr[1]\t$sp\t$ep\n";
}
close IN;
close O;


