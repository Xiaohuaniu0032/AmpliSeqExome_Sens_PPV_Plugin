use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;


my ($input_vcf,$output_vcf) = @ARGV;

# chip1_017.TSVC_variants.bcfnorm.gt_filter.qual_pass.vcf


open O, ">$output_vcf" or die;

open IN, "$input_vcf" or die;
while (<IN>){
	chomp;
	next if /^$/;
	if (/^\#/){
		print O "$_\n";
	}else{
		my @arr = split /\t/, $_;
		my $chr = $arr[0];
		my $qual = $arr[5];

		my $new_qual = $qual + 1000;
		$chr =~ s/^chr//;

		print O "$chr\t$arr[1]\t$arr[2]\t$arr[3]\t$arr[4]\t$new_qual\t$arr[6]\t$arr[7]\t$arr[8]\t$arr[9]\n";
	}
}
close IN;
close O;