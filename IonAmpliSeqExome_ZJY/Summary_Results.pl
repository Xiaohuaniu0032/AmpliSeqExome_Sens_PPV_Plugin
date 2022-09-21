use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my ($indel_summary,$snv_summary,$sample_name,$outfile) = @ARGV;

open O, ">$outfile" or die;
print O "Sample\tVarType\tTP\tFP\tFN\tSensitivity(\%)\tPPV(\%)\n";


# INDEL
my ($indel_TP,$indel_FP,$indel_FN,$indel_sens,$indel_ppv) = (0,0,0,0,0);

open IN, "$indel_summary" or die;
while (<IN>){
	chomp;
	if (/^indel_called_num/){
		my $line = <IN>;
		chomp $line;
		my @line = split /\t/, $line;
		$indel_TP = $line[0];
		$indel_FN = $line[1];
		$indel_sens = $line[3];
	}
	if (/^TP_indel_num/){
		my $line = <IN>;
		chomp $line;
		my @line = split /\t/, $line;
		$indel_FP = $line[1];
		$indel_ppv = $line[3];
	}
}
close IN;

my $TP_Plus_FP_indel = $indel_TP + $indel_FP;
my $TP_Plus_FN_indel = $indel_TP + $indel_FN;

print O "$sample_name\tInDel\t$indel_TP\t$indel_FP\t$indel_FN\t$indel_sens\t$indel_ppv\n";



# SNV
my ($snv_TP,$snv_FP,$snv_FN,$snv_sens,$snv_ppv) = (0,0,0,0,0);

open IN, "$snv_summary" or die;
while (<IN>){
	chomp;
	if (/^call_num/){
		my $line = <IN>;
		chomp $line;
		my @line = split /\t/, $line;
		$snv_TP = $line[0];
		$snv_FN = $line[1];
		$snv_sens = $line[3];
	}

	if (/^tp_num/){
		my $line = <IN>;
		chomp $line;
		my @line = split /\t/, $line;
		$snv_FP = $line[1];
		$snv_ppv = $line[3];
	}
}
close IN;

print O "$sample_name\tSNV\t$snv_TP\t$snv_FP\t$snv_FN\t$snv_sens\t$snv_ppv\n";
close O;