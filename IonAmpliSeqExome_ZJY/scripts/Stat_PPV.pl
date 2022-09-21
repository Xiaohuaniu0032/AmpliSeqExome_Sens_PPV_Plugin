use strict;
use warnings;

my ($TSVC_bcfnorm_pass_vcf,$YH_27M_bed_file,$YH_InDel_HS_vcf,$PPV_outfile,$Sens_PPV_Summary_file) = @ARGV;

# read YH HS InDel file
my %hs_indel;
my %skip_pos;

open HS, "$YH_InDel_HS_vcf" or die;
<HS>;
while (<HS>){
	chomp;
	my @arr = split /\t/;
	
	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	my $var = "$chr\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt

	if ($arr[4] =~ /\,/){
		$skip_pos{$chr}{$arr[1]} = 1; # skip any pos in TSVC file
	}else{
		$hs_indel{$var} = 1;
	}
}
close HS;


# read TSVC bcfnorm file, limit Var into YH 27M BED Region
# Any Var in YH 27M that not in YH HS VCF is the False Positive Call.

my %bed_region;
open BED, "$YH_27M_bed_file" or die;
while (<BED>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;

	my $chr;
	if ($arr[0] =~ /^chr/){
		$chr = $arr[0];
	}else{
		$chr = "chr".$arr[0];
	}

	for my $p ($arr[1]..$arr[2]){
		$bed_region{$chr}{$p} = 1;
	}
}
close BED;

# outfile name: 
# sample_name\.PPV.Flag.xls;
# sample_name\.Sens.PPV.Summary.xls;

my ($tp_num,$fp_num) = (0,0);

open PPV, ">$PPV_outfile" or die;

open SENS_PPV, ">>$Sens_PPV_Summary_file" or die; # add PPV summary result
print SENS_PPV "######################## Stat PPV ########################\n";

my $out_bed_indel_num = 0;

open VCF, "$TSVC_bcfnorm_pass_vcf" or die;
while (<VCF>){
	chomp;
	next if (/^$/);
	next if (/^\#/);
	my @arr = split /\t/;

	if (exists $bed_region{$arr[0]}{$arr[1]}){
		# var in bed file
		if (exists $skip_pos{$arr[0]}{$arr[1]}){
			#print SENS_PPV "[Multi Alt Allele in Gold VCF, Will be Skipped] => $_\n";
			$out_bed_indel_num += 1;
			next;
			# we do not perform bcfnorm for gold vcf, but performed the bcfnorm to TSVC_variants.vcf
			# so if a var in gold vcf has >=2 alt allele, its vcf format in gold vcf may differ from TSVC bcf norm-ed format.
			# multi alt allele is about 1% in Giab NA12878, so skip these pos will not affect out PPV value. 
		}

		my $ref_len = length($arr[3]);
		my $alt_len = length($arr[4]);

		if ($ref_len != $alt_len){
			# indel
			# check this indel if called by TVC
			my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
			
			my $tp_flag;
			if (exists $hs_indel{$var}){
				$tp_flag = "TP";
				$tp_num += 1;
			}else{
				$tp_flag = "FP";
				$fp_num += 1;
			}

			print PPV "$tp_flag\t$_\n";
		}
	}
}
close VCF;
close PPV;

my $tp_fp = $tp_num + $fp_num;
my $ppv = sprintf "%.2f", $tp_num / $tp_fp * 100;

#print SENS_PPV "\n\n\n";
print SENS_PPV "Out of YH 27M Target InDel Num: $out_bed_indel_num\n";
print SENS_PPV "TP_indel_num\tFP_indel_num\tTP_FP_indel_num\tPPV\n";
print SENS_PPV "$tp_num\t$fp_num\t$tp_fp\t$ppv\n";
close SENS_PPV;