use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my ($bcfnorm_vcf,$outfile) = @ARGV;

# chip1.TSVC_variants.bcfnorm.vcf

open O, ">$outfile" or die;


open IN, "$bcfnorm_vcf" or die;
while (<IN>){
	chomp;
	next if /^$/;
	if (/^\#/){
		print O "$_\n";
	}else{
		my @arr = split /\t/;
		my $ref = $arr[3];
		my $alt = $arr[4];
		my $ref_len = length($ref);
		my $alt_len = length($alt);

		if (($ref_len == $alt_len) and ($ref_len >= 2)){
			# MNP
			my $start_pos = $arr[1];
			my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
			print "MNP ===> $var\t$arr[-1]\n";
			my @ref_base = split //, $ref;
			my @alt_base = split //, $alt;

			my $idx = 0;
			my $pos = $start_pos;
			for my $ref_base (@ref_base){
				my $alt_base = $alt_base[$idx];
				$arr[1] = $pos;
				$arr[3] = $ref_base;
				$arr[4] = $alt_base;
				my $line = join("\t",@arr);
				print O "$line\n";
				$idx += 1;
				$pos += 1;
			}
		}else{
			# SNV/INS/DEL
			print O "$_\n";
		}
	}
}
close IN;
close O;