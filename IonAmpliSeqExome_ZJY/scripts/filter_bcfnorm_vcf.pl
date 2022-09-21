use strict;
use warnings;
use File::Basename;
use Getopt::Long;

my ($bcfnorm_vcf_file,$outfile) = @ARGV;

open O, ">$outfile" or die;

open VCF, "$bcfnorm_vcf_file" or die;
while (<VCF>){
	chomp;
	if (/^\#/){
		print O "$_\n";
	}else{
		my @arr = split /\t/;
		my $gt_info = $arr[-1];
		my @gt_info = split /\:/, $gt_info;
		my $gt = $gt_info[0];
		if ($gt ne "0/0" and $gt ne "./."){
			print O "$_\n";
		}else{
			#print "FilterOut\t$_\n";
		}
	}
}
close O;

print "Finished gt <0/0 and ./.> filter\n";
