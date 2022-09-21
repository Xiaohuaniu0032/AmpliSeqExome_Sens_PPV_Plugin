use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

# chip1.TSVC_variants.bcfnorm.splitMNP.vcf

my ($bcfnorm_splitMNP_vcf,$outfile) = @ARGV;

open O, ">$outfile" or die;
print O "chr\tpos\tref\talt\tdup_num\n";


my %var;
open IN, "$bcfnorm_splitMNP_vcf" or die;
while (<IN>){
	chomp;
	next if /^$/;
	next if /^\#/;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	$var{$var} += 1;
}
close IN;

foreach my $var (keys %var){
	my $var_n = $var{$var};
	if ($var_n >= 2){
		# dup var
		print O "$var\t$var_n\n";
	}
}

close O;

