use strict;
use warnings;
use File::Basename;

my ($ppv_infile,,$ppv_detail_outfile) = @ARGV;

# SAR: Alternate allele observations on the reverse strand
# SAF: Alternate allele observations on the forward strand
# AO : Alternate allele observations

# FSAR: Flow Evaluator Alternate allele observations on the reverse strand
# FSAF: Flow Evaluator Alternate allele observations on the forward strand
# FAO : Flow Evaluator Alternate allele observations

# DP : Raw Depth
# FDP: Flow Corrected Depth
# AF : FAO/FDP

################### Output PPV TVC Detail ###################

# read ppv file and output TVC detail info

open O, ">$ppv_detail_outfile" or die;
print O "\#TP_or_FP\tTVC_Var\tTVC_GT\tTVC_QUAL\tTVC_MLLD\tTVC_STB\tTVC_RBI\tTVC_FR\tTVC_AO\tTVC_FAO\tTVC_DP\tTVC_FDP\tTVC_AF\n";

open IN, "$ppv_infile" or die;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $var = "$arr[1]\.$arr[2]\.$arr[4]\.$arr[5]"; # chr.pos.ref.alt

	my @info = split /\:/, $arr[-1];
	my $gt   = $info[0];
	#my $qual = "GQ=".$info[1];
	my $qual = "QUAL=".int($arr[6]);
	my $AO   = "AO=".$info[6];
	my $FAO  = "FAO=".$info[7];
	my $DP   = "DP=".$info[2];
	my $FDP  = "FDP=".$info[3];
	my $AF   = "AF=".$info[8];

	# get MLLD | STB | RBI | FR
	my ($MLLD,$STB,$RBI,$FR) = qw/NA NA NA NA/;

	my @info2 = split /\;/, $arr[8];
	for my $item (@info2){
		if ($item =~ /^MLLD=/){
			$MLLD = $item
		}
		if ($item =~ /^STB=/){
			$STB = $item
		}
		if ($item =~ /^RBI=/){
			$RBI = $item;
		}
		if ($item =~ /^FR=/){
			$FR = $item;
		}
	}

	print O "$arr[0]\t$var\t$gt\t$qual\t$MLLD\t$STB\t$RBI\t$FR\t$AO\t$FAO\t$DP\t$FDP\t$AF\n";
}
close IN;
close O;
