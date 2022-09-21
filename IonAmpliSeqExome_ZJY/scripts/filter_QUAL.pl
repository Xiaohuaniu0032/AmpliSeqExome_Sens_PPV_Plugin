use strict;
use warnings;

my ($gt_filter_vcf,$qual_cutoff,$MLLD_cutoff,$outfile_vcf) = @ARGV;

print "Qual filter cutoff is: $qual_cutoff\n";
print "MLLD filter cutoff is: $MLLD_cutoff\n";

open O, ">$outfile_vcf" or die;

open IN, "$gt_filter_vcf" or die;
while (<IN>){
	chomp;
	if (/^\#/){
		print O "$_\n";
	}else{
		my @arr = split /\t/;
		my $qual = $arr[5];
		my $info = $arr[7];
		my @info = split /\;/,$info;
		
		# some lines in vcf do not have MLLD tag. indel call?
		my $MLLD;
		my $MLLD_tag = 0;
		for my $item (@info){
			if ($item =~ /^MLLD=/){
				$MLLD = (split /\=/, $item)[1];
				$MLLD_tag = 1;
				last;
			}
		}
		
		if ($MLLD_tag == 1){
			if ($qual >= $qual_cutoff and $MLLD >= $MLLD_cutoff){
				print O "$_\n";
			}else{
				print "[QUAL_Low | MLLD_Low]\t$_\n";
			}
		}else{
			if ($qual >= $qual_cutoff){
				print O "$_\n";
			}else{
				print "[QUAL_Low | MLLD_Low]\t$_\n";
			}
		}
	}
}
close IN;
close O;