use strict;
use warnings;

my ($Sens_file,$outfile) = @ARGV;

 
my ($cov_5x,$cov_10x,$cov_20x) = (0,0,0);
my $hs_num = 0;

open DEPTH, ">$outfile" or die;
print DEPTH "Chr\tPos\tRef\tAlt\tAO\tFAO\tDP\tFDP\n";

open IN, "$Sens_file" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	next if ($arr[-1] eq "NA");
	
	my $var = $arr[1]; # chr1.1116188.CG.C
	my @var = split /\./, $var;
	
	my $AO  = (split /\=/, $arr[-6])[1];
	my $FAO = (split /\=/, $arr[-5])[1];

	my $DP  = int((split /\=/, $arr[-4])[1]);
	my $FDP = (split /\=/, $arr[-3])[1];

	print DEPTH "$var[0]\t$var[1]\t$var[2]\t$var[3]\t$AO\t$FAO\t$DP\t$FDP\n";

	if ($DP >= 5){
		$cov_5x += 1;
	}

	if ($DP >= 10){
		$cov_10x += 1;
	}

	if ($DP >= 20){
		$cov_20x += 1;
	}

	$hs_num += 1;
}
close IN;

my ($cov_5x_pct,$cov_10x_pct,$cov_20x_pct) = (0,0,0);

if ($cov_5x > 0){
	$cov_5x_pct = sprintf "%.2f", $cov_5x / $hs_num * 100;
}else{
	$cov_5x_pct = 0;
}

if ($cov_10x > 0){
	$cov_10x_pct = sprintf "%.2f", $cov_10x / $hs_num * 100;
}else{
	$cov_10x_pct = 0;
}

if ($cov_20x > 0){
	$cov_20x_pct = sprintf "%.2f", $cov_20x / $hs_num *100;
}else{
	$cov_20x_pct = 0;
}

print DEPTH "###### Depth Summary Info ######\n";
print DEPTH "Depth(Raw_DP)\tNum\tTotal_Num\tPct(\%)\n";
print DEPTH ">=5X\t$cov_5x\t$hs_num\t$cov_5x_pct\n";
print DEPTH ">=10X\t$cov_10x\t$hs_num\t$cov_10x_pct\n";
print DEPTH ">=20X\t$cov_20x\t$hs_num\t$cov_20x_pct\n";

close DEPTH;
