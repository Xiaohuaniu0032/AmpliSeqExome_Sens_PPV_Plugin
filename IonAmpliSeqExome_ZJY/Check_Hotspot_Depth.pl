use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my $YH_indel = "$Bin/indel/YH-indel.vcf";

my ($depth_file,$name,$outfile) = @ARGV;

open O, ">$outfile" or die;
print O "chr\tpos\tdepth\n";

my %hs_vars;
open IN, "$YH_indel" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $chr = $arr[0];
	my $pos = $arr[1];
	my $var = "$chr\t$pos";
	$hs_vars{$var} = 1;
}
close IN;


my $cov_20x_num = 0;

my %exists;
open IN, "$depth_file" or die;
while (<IN>){
	chomp;
	next if /^$/;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]";
	my $depth = $arr[2];

	if (exists $hs_vars{$var}){
		print O "$_\n";
		$exists{$var} = 1;

		if ($depth >= 20){
			$cov_20x_num += 1;
		}
	}


}
close IN;

my %not_exists;
foreach my $var (keys %hs_vars){
	if (!exists $exists{$var}){
		$not_exists{$var} = 1;
		print O "$var\tNA\n";
	}
}


### 统计深度信息
my $total_hs_num = keys %hs_vars;
print O "total_hs_num: $total_hs_num\n";
print O "cov>=20x_num: $cov_20x_num\n";

close O;

print "Finished runing Check_Hotspot_Depth.pl...\n";