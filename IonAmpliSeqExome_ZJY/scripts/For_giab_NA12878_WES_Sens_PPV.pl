use strict;
use warnings;

my ($tvc_vcf_file, $giab_vcf_file, $sample_name, $outdir) = @ARGV;

# Please note: giab vcf was extract based on agilent v6 bed region from giab WGS vcf.
# So in theory, all variants in tvc should be equal with agilent.giab.vcf. this means 100% sens and 100 spec.

# 检查indel hs文件是否存在
if (! -e $giab_vcf_file){
	die "can not find giab wes vcf file: $giab_vcf_file\n";
}


##################### 统计SNV/InDel灵敏度 #################
print "[INFO] Check snv/indel sensitivity...\n";
my $stat_file_for_sensitivity = "$outdir/$sample_name\.Sensitivity.xls";
open SENS, ">$stat_file_for_sensitivity" or die;

my %tvc_vars;
open IN, "$tvc_vcf_file" or die;
while (<IN>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt.
	$tvc_vars{$var} = 1;
}
close IN;

my $snv_call_num = 0;
my $snv_not_call_num = 0;
	
my $indel_call_num = 0;
my $indel_not_call_num = 0;


open GIAB, "$giab_vcf_file" or die;
while (<GIAB>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;

	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt

	my $var_type;
	my $len_ref = length($arr[3]);
	my $len_alt = length($arr[4]);
	if ($len_ref == $len_alt){
		$var_type = "SNV";
	}else{
		$var_type = "InDel";
	}

	my $if_call;
	if ($var_type eq "SNV"){
		if (exists $tvc_vars{$var}){
			$snv_call_num += 1;
			$if_call = "Called";
		}else{
			$snv_not_call_num += 1;
			$if_call = "NotCalled";
		}
	}else{
		if (exists $tvc_vars{$var}){
			$indel_call_num += 1;
			$if_call = "Called";
		}else{
			$indel_not_call_num += 1;
			$if_call = "NotCalled";
		}
	}
	
	print SENS "$if_call\t$var_type\t$var\t$_\n";
}
close GIAB;
close SENS;


# stat snv sens
my $snv_num = $snv_call_num + $snv_not_call_num;
my $snv_sens = sprintf "%.2f", $snv_call_num/$snv_num * 100;
print "snv_called_num\tsnv_not_called_num\tsnv_total_num\tsnv_sensitivity(\%)\n";
print "$snv_call_num\t$snv_not_call_num\t$snv_num\t$snv_sens\n";

# stat indel sens
my $indel_num = $indel_call_num + $indel_not_call_num;
my $indel_sens = sprintf "%.2f", $indel_call_num/$indel_num * 100;
print "indel_called_num\tindel_not_called_num\tindel_total_num\tindel_sensitivity(\%)\n";
print "$indel_call_num\t$indel_not_call_num\t$indel_num\t$indel_sens\n";




################# 统计SNV/InDel PPV #############
print "\n[INFO] Check snv/indel PPV...\n";
my $stat_file_for_ppv = "$outdir/$sample_name\.PPV.xls";
open SPEC, ">$stat_file_for_ppv" or die;


my $snv_tp_num = 0;
my $indel_tp_num = 0;

my %giab_vars;
open GIAB, "$giab_vcf_file" or die;
while (<GIAB>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	
	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $var_type;
	my $len_ref = length($arr[3]);
	my $len_alt = length($arr[4]);

	if ($len_ref == $len_alt){
		$var_type = "SNV";
		$snv_tp_num += 1;
	}else{
		$var_type = "InDel";
		$indel_tp_num += 1;
	}

	my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	$giab_vars{$var} = 1;
}
close GIAB;

my ($tvc_snv_tp,$tvc_snv_fp);
my ($tvc_indel_tp,$tvc_indel_fp);

open TVC, "$tvc_vcf_file" or die;
while (<TVC>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt

	my $len_ref = length($arr[3]);
	my $len_alt = length($arr[4]);

	my $var_type;
	if ($len_ref == $len_alt){
		$var_type = "SNV";
	}else{
		$var_type = "InDel";
	}

	my $if_call;
	if ($var_type eq "SNV"){
		if (exists $giab_vars{$var}){
			$tvc_snv_tp += 1;
			$if_call = "TP"
		}else{
			$tvc_snv_fp += 1;
			$if_call = "FP";
		}
	}else{
		if (exists $giab_vars{$var}){
			$tvc_indel_tp += 1;
			$if_call = "TP"
		}else{
			$tvc_indel_fp += 1;
			$if_call = "FP";
		}
	}

	print SPEC "$if_call\t$var_type\t$var\t$_\n";
}

close TVC;
close SPEC;


# stat snv spec
my $snv_tp_fp = $tvc_snv_tp + $tvc_snv_fp;
my $snv_ppv = sprintf "%.2f", $tvc_snv_tp / $snv_tp_fp * 100;

print "tvc_snv_tp\ttvc_snv_fp\ttvc_snv_tp_fp\ttvc_snv_PPV(\%)\n";
print "$tvc_snv_tp\t$tvc_snv_fp\t$snv_tp_fp\t$snv_ppv\n";

# stat indel spec
my $indel_tp_fp = $tvc_indel_tp + $tvc_indel_fp;
my $indel_ppv = sprintf "%.2f", $tvc_indel_tp/$indel_tp_fp * 100;

print "tvc_indel_tp\ttvc_indel_fp\ttvc_indel_tp_fp\ttvc_indel_PPV(\%)\n";
print "$tvc_indel_tp\t$tvc_indel_fp\t$indel_tp_fp\t$indel_ppv\n";

