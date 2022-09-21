use strict;
use warnings;

my ($Sens_TVC_outfile,$outfile) = @ARGV;

# 统计NotCall的FR
my ($Ref_Call,$Low_Cov,$NODATA,$PREDICTIONSHIFT,$Strand_Bias,$Others) = (0,0,0,0,0,0);

my %others;

open IN, "$Sens_TVC_outfile" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $gt = $arr[-1];
	my $FR = $arr[-7];
	if ($arr[0] eq "NotCalled"){
		if ($gt eq "GT=0/0"){
			# ref call
			$Ref_Call += 1;
		}elsif ($FR =~ /MINCOV/ || $FR =~ /PosCov/ || $FR =~ /NegCov/){
			# low cov
			# hotspot_min_cov = 6
			$Low_Cov += 1;
		}elsif ($FR =~ /NODATA/){
			# FDP = 0
			$NODATA += 1;
		}elsif ($FR =~ /PREDICTIONSHIFT/){
			$PREDICTIONSHIFT += 1;
		}elsif ($FR =~ /STDBIAS/){
			$Strand_Bias += 1;
		}else{
			$Others += 1;
			push @{$others{$FR}}, $_;
		}
	}
}
close IN;


my $n = $Ref_Call + $Low_Cov + $NODATA + $PREDICTIONSHIFT + $Others + $Strand_Bias;

my $ref_call_pct = sprintf "%.2f", $Ref_Call / $n * 100;
my $low_cov_pct  = sprintf "%.2f", $Low_Cov  / $n * 100; 
my $no_data_pct  = sprintf "%.2f", $NODATA   / $n * 100;
my $predshif_pct = sprintf "%.2f", $PREDICTIONSHIFT / $n * 100;
my $others_pct   = sprintf "%.2f", $Others   / $n * 100;
my $stdbias      = sprintf "%.2f", $Strand_Bias / $n * 100;


open O, ">$outfile" or die;
print O "#Total_FN: $n\n\n";
print O "#NoCallReason\tNum\tTotal_Num\tPct(\%)\n";

print O "Ref_Call\t$Ref_Call\t$n\t$ref_call_pct\n";
print O "Low_Cov\t$Low_Cov\t$n\t$low_cov_pct\n";
print O "NODATA\t$NODATA\t$n\t$no_data_pct\n";
print O "PREDICTIONSHIFT\t$PREDICTIONSHIFT\t$n\t$predshif_pct\n";
print O "Strand_Bias\t$Strand_Bias\t$n\t$stdbias\n";
print O "Others\t$Others\t$n\t$others_pct\n";


print O "\n\n\n";
print O "#Other False Negtive Variants#\n";

foreach my $FR (keys %others){
	my @vars = @{$others{$FR}};
	my $n_var = scalar(@vars);
	print O "$FR\t$n_var\n";
}

print O "\n\n";

foreach my $FR (keys %others){
	my @vars = @{$others{$FR}};
	my $n_var = scalar(@vars);
	print O "$FR\t$n_var\n";

	for my $var (@vars){
		print O "    ===> $var\n";
	}
	print O "\n";
}

close O;
