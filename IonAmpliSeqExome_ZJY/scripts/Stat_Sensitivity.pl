use strict;
use warnings;

my ($tvc_vcf_file, $indel_hs_vcf, $sample_name, $Sens_outfile, $Sens_PPV_outfile) = @ARGV;

# Please note: giab vcf was extract based on agilent v6 bed region from giab WGS vcf.
# So in theory, all variants in tvc should be equal with agilent.giab.vcf. this means 100% sens and 100 spec.

# 检查indel hs文件是否存在
if (!-e $indel_hs_vcf){
	die "can not find $indel_hs_vcf, please check these file(s)\n";
}

my %skip_rs;
open VCF, "$indel_hs_vcf" or die;
while (<VCF>){
	chomp;
	next if (/^$/);
	next if (/^\#/);
	my @arr = split /\t/;
	my $alt = $arr[4];
	if ($alt =~ /\,/){
		# this pos has >=2 alt alleles
		# in giab NA12878, multi allele var is about 1%, so do not consider there multi allele vars will not affect the final results.
		$skip_rs{$arr[2]} = 1;
	}
}
close VCF;

open SENS, ">$Sens_outfile" or die;

open SENS_PPV, ">$Sens_PPV_outfile" or die;
print SENS_PPV "######################## Stat Senesitivity ########################\n";

################# 统计InDel灵敏度 ################

# read tvc results, and for each var in gold vcf, check if it is called by TVC

# first read tvc results
my %tvc_vars;
open IN, "$tvc_vcf_file" or die;
while (<IN>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt. here we do not consider GT
	$tvc_vars{$var} = 1;
}

# then check each var in gold vcf
my ($called_num,$not_called_num) = (0,0);

open HS, "$indel_hs_vcf" or die;
while (<HS>){
	chomp;
	next if (/^\#/);
	next if (/^$/);
	my @arr = split /\t/;
	
	my $rs = $arr[2];
	if (exists $skip_rs{$rs}){
		print SENS_PPV "###[This Var will be skipped for multi alt allele] => $_\n\n";
	}

	my $alt = $arr[4];
	next if ($alt =~ /\,/); # skip multi alt vars

	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt

	my $if_call;
	if (exists $tvc_vars{$var}){
		$if_call = "Called";
		$called_num += 1;
	}else{
		$if_call = "NotCalled";
		$not_called_num += 1;
	}

	print SENS "$if_call\t$_\n";

}
close HS;
close SENS;


# stat indel sens
my $indel_all_num = $called_num + $not_called_num;
my $indel_sens = sprintf "%.2f", $called_num / $indel_all_num * 100;

print SENS_PPV "indel_called_num\tindel_not_called_num\tindel_total_num\tindel_sensitivity(\%)\n";
print SENS_PPV "$called_num\t$not_called_num\t$indel_all_num\t$indel_sens\n";
print SENS_PPV "\n\n\n\n";
close SENS_PPV;
