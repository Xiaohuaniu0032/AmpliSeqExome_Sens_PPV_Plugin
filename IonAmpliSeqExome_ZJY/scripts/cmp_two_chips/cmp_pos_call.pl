use strict;
use warnings;

# check false positive identical

my ($chip1_PPV,$chip2_PPV,$outfile) = @ARGV;

my %all_fp;

my @fp_var_uniq;
my %fp_flag;


my %chip1_fp;
open C1, "$chip1_PPV" or die;
while (<C1>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	my $tp_fp = $arr[0]; # TP / FP
	my $var = $arr[1];
	if ($tp_fp eq "FP"){
		# a FP call
		$chip1_fp{$var} = 1;
		$all_fp{$var} = 1;

		if (not exists $fp_flag{$var}){
			push @fp_var_uniq, $var;
			$fp_flag{$var} = 1;
		}
	}
}
close C1;

open C2, "$chip2_PPV" or die;
while (<C2>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	my $tp_fp = $arr[0]; # TP / FP
	my $var = $arr[1];
	if ($tp_fp eq "FP"){
		# a FP call
		$chip2_fp{$var} = 1;
		$all_fp{$var} = 1;

		if (not exists $fp_flag{$var}){
			push @fp_var_uniq, $var;
			$fp_flag{$var} = 1;
		}
	}
}
close C2;

# get both fp call num
my $both_fp_num = 0;

foreach my $var (keys %all_fp){
	if (exists $chip1_fp{$var} and exists $chip2_fp{$var}){
		# this var is a fp in chip1 and chip2
		$both_fp_num += 1;
	}
}

open O, ">$outfile" or die;
print O "chip1_fp\tchip2_fp\tidentical\tchip1_identical\tchip2_identical\n";

my $chip1_fp_num = scalar(keys %chip1_fp);
my $chip2_fp_num = scalar(keys %chip2_fp);

my $chip1_iden = sprintf "%.2f", $both_fp_num / $chip1_fp_num * 100;
my $chip2_iden = sprintf "%.2f", $both_fp_num / $chip2_fp_num * 100;

print O "$chip1_fp_num\t$chip2_fp_num\t$both_fp_num\t$chip1_iden\t$chip2_iden\n";
print O "\n\n";



# output detail FP call
undef %chip1_fp;
undef %chip2_fp;

open C1, "$chip1_PPV" or die;
while (<C1>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	next if ($arr[0] eq "TP"); # only keep FP call
	my $var = $arr[1];
	$var_info = "$arr[3]\;$arr[4]\;$arr[5]\;$arr[6]\;$arr[7]\;$arr[8]\;$arr[9]\;$arr[10]\;$arr[11]\;$arr[12]\;$arr[2]"; # QUAL/MLLD/STB/RBI/FR/AO/FAO/DP/FDP/AF/GT
	$chip1_fp{$var} = $var_info;
}
close C1;

open C2, "$chip2_PPV" or die;
while (<C2>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	next if ($arr[0] eq "TP"); # only keep FP call
	my $var = $arr[1];
	$var_info = "$arr[3]\;$arr[4]\;$arr[5]\;$arr[6]\;$arr[7]\;$arr[8]\;$arr[9]\;$arr[10]\;$arr[11]\;$arr[12]\;$arr[2]"; # QUAL/MLLD/STB/RBI/FR/AO/FAO/DP/FDP/AF/GT
	$chip2_fp{$var} = $var_info;
}
close C2;

# 循环每个FP var 检查其在chip1/chip2中是否共同出现
for my $var (@fp_var_uniq){
	
	if (exists $chip1_fp{$var} and exists $chip2_fp{$var}){
		# 共同出现

	}
}



