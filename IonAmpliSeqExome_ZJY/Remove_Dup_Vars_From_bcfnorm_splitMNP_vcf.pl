use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;


my ($dup_var_xls,$bcfnorm_splitMNP_vcf,$outfile) = @ARGV;

open O, ">$outfile" or die;


# 记录重复的变异位点
my %dup_vars;
open IN, "$dup_var_xls" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[2]\t$arr[3]"; # chr/pos/ref/alt
	$dup_vars{$var} = 1;
}
close IN;


# 对于重复位点,取出该位点所有的行
my %dup_vars_wait_to_select;
open IN, "$bcfnorm_splitMNP_vcf" or die;
while (<IN>){
	chomp;
	next if /^\#/;
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	if (exists $dup_vars{$var}){
		push @{$dup_vars_wait_to_select{$var}}, $_;
	}
}
close IN;


# 从重复位点中选择最优位点
my %best_uniq_var;
foreach my $var (keys %dup_vars_wait_to_select){
	my @all_var = @{$dup_vars_wait_to_select{$var}};
	my @pass_var;

	my @var = split /\t/, $var;

	my $ref = $var[2];
	my $alt = $var[3];

	my $ref_len = length($ref);
	my $alt_len = length($alt);


	if ($ref_len == $alt_len){
		# SNV
		# 在allow_mnp时,SNV的频率可能有问题.不过这种位点很少,不会影响SNV的灵敏度和PPV

		# TSVC_variants.vcf
		# chr4    80905990        .       CG      GC,GG   3567.34 PASS    AF=0.605,0.3825; GT=1/2
		
		# chip1.TSVC_variants.bcfnorm.vcf
		# chr4    80905990        .       CG      GC      3567.34 PASS    AF=0.605; GT=1/0
		# chr4    80905990        .       C       G       3567.34 PASS    AF=0.3825;GT=0/1

		# chip1.TSVC_variants.bcfnorm.splitMNP.vcf
		# chr4    80905990        .       C       G       3567.34 PASS    AF=0.605;
		# chr4    80905990        .       C       G       3567.34 PASS    AF=0.3825;

		# 80905990:C->G频率应该是98.75%
		for my $item (@all_var){
			my @item = split /\t/, $item;
			if ($item[6] eq "PASS"){
				push @pass_var, $item;
			}
		}
	}else{
		# INDEL
		for my $item (@all_var){
			my @item = split /\t/, $item;
			if ($item[6] eq "PASS"){
				push @pass_var, $item;
			}
		}
	}

	my $pass_var_n = scalar(@pass_var);

	if ($pass_var_n >= 1){
		my $best_var = $pass_var[0];
		$best_uniq_var{$var} = $best_var;
	}
}


# 读取bcfnorm.splitMNP.vcf,对重复位点进行过滤

open IN, "$bcfnorm_splitMNP_vcf" or die;
while (<IN>){
	chomp;
	if (/^\#/){
		print O "$_\n";
	}else{
		my @arr = split /\t/;
		my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
		if (exists $dup_vars_wait_to_select{$var}){
			# 检查是否是best uniq var
			my $best_var = $best_uniq_var{$var};
			if ($best_var eq $_){
				print O "$_\n";
			}else{
				next;
			}
		}else{
			print O "$_\n";
		}
	}
}
close IN;
close O;


