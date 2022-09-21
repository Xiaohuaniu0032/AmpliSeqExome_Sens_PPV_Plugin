use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;


my ($bcfnorm_vcf,$Outfile) = @ARGV;
# chip1.TSVC_variants.bcfnorm.rmdup.vcf

my $YH_indel = "$Bin/indel/YH-indel.vcf";

my %indel;
open IN, "$YH_indel" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	$indel{$var} = 1;
}
close IN;

my @flow_wrong;
my @flow_ok;

open O, ">$Outfile" or die;


# 检查Flow矫正问题:哪些位点AO!=0但FAO=0,或者DP!=0但FDP=0

open IN, "$bcfnorm_vcf" or die;
while (<IN>){
	chomp;
	next if /^$/;
	next if /^\#/;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	if (exists $indel{$var}){
		# 热点
		my $info = $arr[7];
		my @info = split /\;/, $info;
		
		my ($AO,$FAO,$DP,$FDP);
		for my $item (@info){
			if ($item =~ /^AO=/){
				$AO = (split /\=/, $item)[1];
			}
			if ($item =~ /^FAO=/){
				$FAO = (split /\=/, $item)[1];
			}
			if ($item =~ /^DP=/){
				$DP = (split /\=/, $item)[1];
			}
			if ($item =~ /^FDP=/){
				$FDP = (split /\=/, $item)[1];
			}
		}
		#print "$_\n";
		
		if (defined $AO and defined $FAO and defined $DP and defined $FDP){
			my $var = "$arr[0]\t$arr[1]\t$arr[2]\t$arr[3]\t$arr[4]\t$AO\t$FAO\t$DP\t$FDP";
			if (($AO!=0 and $FAO==0) || ($DP!=0 and $FDP==0)){
				push @flow_wrong, $var;
			}else{
				push @flow_ok, $var;
			}
		}
	}
}
close IN;


my $flow_wrong_n = scalar(@flow_wrong);
my $flow_ok_n = scalar(@flow_ok);

print O "Flow Wrong Num: $flow_wrong_n\n";
print O "Flow OK Num: $flow_ok_n\n";

print O "Flow Wrong YH_indel:\n";
print O "Chr\tPos\tID\tRef\tAlt\tAO\tFAO\tDP\tFDP\n";
for my $item (@flow_wrong){
	print O "\t$item\n";
}

print O "Flow OK YH_indel:\n";
for my $item (@flow_ok){
	print O "\t$item\n";
}
close O;

