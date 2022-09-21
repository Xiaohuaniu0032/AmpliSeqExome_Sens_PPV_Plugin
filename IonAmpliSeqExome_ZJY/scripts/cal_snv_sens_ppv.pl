use strict;
use warnings;

my ($gold_snv_vcf,$infile,$YH_BED,$sens_outfile,$ppv_outfile) = @ARGV;

# infile is *.TSVC_variants.bcfnorm.splitMNP.rmdup.pass_gt_filter.pass_QUAL_and_MLLD.vcf


# YH 27M BED区间
my %yh_site;
open BED, "$YH_BED" or die;
while (<BED>){
	chomp;
	my @arr = split /\t/;
	my $chr = $arr[0];
	my $sp = $arr[1] + 1;
	my $ep = $arr[2];
	for my $pos ($sp..$ep){
		my $chr_pos = "$chr\t$pos";
		$yh_site{$chr_pos} = 1;
	}
}
close BED;



# TVC检出的SNV位点
my %snv;
open TSVC, "$infile" or die;
while (<TSVC>){
	chomp;
	next if (/^$/);
	next if (/^\#/);
	my @arr = split /\t/;

	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $pos = $arr[1];
	my $chr_pos = "$chr\t$pos";
	next if (not exists $yh_site{$chr_pos}); # skip pos that not in 27M region

	my $ref = $arr[3];
	my $alt = $arr[4];

	my $ref_len = length($ref);
	my $alt_len = length($alt);

	#my $gt = (split /\:/, $arr[-1])[0];

	if (($ref_len == $alt_len) and ($ref_len == 1)){
		if ($arr[6] eq "PASS"){
			my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt; do not consider gt
			$snv{$var} = 1;
		}
	}
}
close TSVC;




# 统计SNV灵敏度
# 检查每一个YH.vcf中的SNV位点，是否被检出
open O, ">$sens_outfile" or die;
print O "#If_Call\tCHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tYH\n";

my ($call_num,$not_call_num) = (0,0);
my %gold_snv;

open IN, "$gold_snv_vcf" or die;
while (<IN>){
	chomp;
	next if (/^$/);
	next if (/^\#/);
	my @arr = split /\t/;
	
	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $pos = $arr[1];
	next if (not defined $pos); # 异常处理
	my $chr_pos = "$chr\t$pos";
	next if (not exists $yh_site{$chr_pos}); # 跳过不在YH BED中的位点

	my $ref_len = length($arr[3]);
	my $alt_len = length($arr[4]);
	
	if ($ref_len != $alt_len){
		next;
	}else{
		my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt; do not consider gt
		$gold_snv{$var} = 1;

		### 检查YH.vcf中的位点是否正确检出.
		### 评估灵敏度
		my $flag;
		if (exists $snv{$var}){ # 是否被TVC检出
			$flag = "Called";
		}else{
			$flag = "NotCalled";
		}

		if ($flag eq "Called"){
			$call_num += 1;
		}else{
			$not_call_num += 1;
		}

		print O "$flag\t$_\n";
	}
}
close IN;
close O;


my $all_snv = $call_num + $not_call_num;
my $sens = sprintf "%.2f", $call_num / $all_snv * 100;
print "################# Stat SNV Sensitivity ######################\n";
print "call_num\tnot_call_num\tall_num\tsensitivity\n";
print "$call_num\t$not_call_num\t$all_snv\t$sens\n";




################################# 统计PPV #####################################
open PPV, ">$ppv_outfile" or die;
print PPV "#TP_or_FP\tCHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tYH\n";


# 检查TVC每一个SNV，判断是TP还是FP
my ($tp_num, $fp_num) = (0,0);
open TSVC, "$infile" or die;
while (<TSVC>){
	chomp;
	next if (/^$/);
	next if (/^\#/);
	my @arr = split /\t/;

	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $pos = $arr[1];
	my $chr_pos = "$chr\t$pos";
	next if (not exists $yh_site{$chr_pos}); # skip pos that not in 27M region


	# 判断是否是SNV
	my $ref = $arr[3];
	my $alt = $arr[4];

	my $ref_len = length($ref);
	my $alt_len = length($alt);

	if (($ref_len == $alt_len) and ($ref_len == 1)){
		# SNV位点
		if ($arr[6] eq "PASS"){
			my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt; do not consider gt
			
			### 判断检查的位点是TP/FP
			my $flag;
			if (exists $gold_snv{$var}){
				$flag = "TP";
				$tp_num += 1;
			}else{
				$flag = "FP";
				$fp_num += 1;
			}

			print PPV "$flag\t$_\n";
		}
	}
}
close TSVC;
close PPV;

my $pos = $tp_num + $fp_num;
my $ppv = sprintf "%.2f", $tp_num / $pos * 100;

print "################# Stat SNV PPV ######################\n";
print "tp_num\tfp_num\tall_num\tppv\n";
print "$tp_num\t$fp_num\t$pos\t$ppv\n";


print "####################### Summary ###########################\n";
print "SNV_Sensitivity: $sens\% \n";
print "SNV_PPV        : $ppv\% \n";