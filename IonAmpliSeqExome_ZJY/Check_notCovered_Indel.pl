use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my $yh_indel = "$Bin/indel/YH-indel.vcf";

my %not_cover_pos;
my $notCovered = "$Bin/YH27Mbed_notCovered.txt";
open IN, "$notCovered" or die;
<IN>;
while (<IN>){
	chomp;
	next if /^$/;
	my @arr = split /\t/;
	my $chr = $arr[0];
	my $start = $arr[1];
	my $end = $arr[2];
	for my $pos ($start..$end){
		$not_cover_pos{$chr}{$pos} = 1;
	}
}
close IN;



open IN, "$yh_indel" or die;
<IN>;
while (<IN>){
	chomp;
	next if /^$/;
	my @arr = split /\t/;
	my $chr = $arr[0];
	my $pos = $arr[1];
	if (exists $not_cover_pos{$chr}{$pos}){
		print "[NotCovered] $_\n";
	}
}
close IN;