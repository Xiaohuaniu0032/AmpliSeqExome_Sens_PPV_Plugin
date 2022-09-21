use strict;
use warnings;
use File::Basename;

my ($sens_vcf,$tsvc_bcfnorm_vcf,$sens_detail_outfile) = @ARGV;

# SAR: Alternate allele observations on the reverse strand
# SAF: Alternate allele observations on the forward strand
# AO : Alternate allele observations

# FSAR: Flow Evaluator Alternate allele observations on the reverse strand
# FSAF: Flow Evaluator Alternate allele observations on the forward strand
# FAO : Flow Evaluator Alternate allele observations

# DP : Raw Depth
# FDP: Flow Corrected Depth
# AF : FAO/FDP

################### Output Sens TVC Detail ###################
my %tvc_detail;
open TVC, "$tsvc_bcfnorm_vcf" or die;
while (<TVC>){
	chomp;
	next if (/^\#/);
	my @arr = split /\t/;

	my ($QUAL,$MLLD,$RBI,$STB,$Call_Res,$FR) = qw/NA NA NA NA NA NA/;
	my ($AO,$FAO,$DP,$FDP,$AF,$GT)           = qw/NA NA NA NA NA NA/;
	
	#$QUAL     = "QUAL=".int($arr[5]);
	$QUAL     = int($arr[5]);
	$Call_Res = $arr[6];

	my $var = "$arr[0]\.$arr[1]\.$arr[3]\.$arr[4]"; # chr/pos/ref/alt

	# get MLLD and FR info
	my $alt_detail = $arr[7]; # AF=0.0666667;AO=0;DP=15;FAO=1;FDP=15;FDVR=5;FR=.&QualityScore<10&STDBIAS0.990802>0.95&STDBIASPVAL0.284<1;FRO=14;FSAF=1;FSAR=0;FSRF=6;FSRR=8;FWDB=-0.0459719;FXX=0;HRUN=1;HS_ONLY=0;LEN=1;MLLD=104.469;OALT=G;OID=rs1639661097;OMAPALT=G;OPOS=17356;OREF=A;PB=0.928571;PBP=0.216;QD=0.983474;RBI=0.0573698;REFB=-0.000975187;REVB=0.0343203;RO=14;SAF=0;SAR=0;SRF=6;SRR=8;SSEN=0;SSEP=0;SSSB=-4.25252e-08;STB=0.990802;STBP=0.284;TYPE=snp;VARB=0.0126649;HS
	my @alt_detail = split /\;/, $alt_detail;
	for my $item (@alt_detail){
		if ($item =~ /MLLD=/){
			$MLLD = (split /\=/, $item)[1];
		}

		if ($item =~ /FR=/){
			$FR = $item;
		}

		if ($item =~ /RBI=/){
			$RBI = (split /\=/, $item)[1];
		}

		if ($item =~ /STB=/){
			$STB = (split /\=/, $item)[1];
		}
	}

	# get GT col
	my $gt_info = $arr[-1];
	my @gt_info = split /\:/, $gt_info;

	$AO  = "AO=".$gt_info[6];
	$FAO = "FAO=".$gt_info[7];
	$DP  = "DP=".$gt_info[2];
	$FDP = "FDP=".$gt_info[3];
	$AF  = "AF=".$gt_info[8];
	$GT  = "GT=".$gt_info[0]; # 0/1 | ./. | 0/0

	
	$tvc_detail{$var} = "$QUAL\t$MLLD\t$STB\t$RBI\t$Call_Res\t$FR\t$AO\t$FAO\t$DP\t$FDP\t$AF\t$GT"; # QUAL/MLLD/STB/RBI/FR/TVC_Res/AO/FAO/DP/FDP/AF/GT
	
}
close TVC;



# read sensitivity file and output each InDel HS's TVC detail info

open O, ">$sens_detail_outfile" or die;
print O "\#If_Call\tHS_Var\tHS_GT\tTVC_QUAL\tTVC_MLLD\tTVC_STB\tTVC_RBI\tTVC_RESULT\tTVC_FR\tTVC_AO\tTVC_FAO\tTVC_DP\tTVC_FDP\tTVC_AF\tTVC_GT\n";

open IN, "$sens_vcf" or die;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $gt = "GT=".(split /\:/, $arr[-1])[0]; # GT:DP:ADALL:AD:GQ 0/1:778:397,381:397,381:99
	
	my $chr;
	if ($arr[1] =~ /^chr/){
		$chr = $arr[1];
	}else{
		$chr = "chr".$arr[1];
	}

	my $var = "$chr\.$arr[2]\.$arr[4]\.$arr[5]"; # chr.pos.ref.alt
	
	my $tvc_info;
	if (exists $tvc_detail{$var}){
		$tvc_info = $tvc_detail{$var};
	}else{
		$tvc_info = join "\t", qw/NA NA NA NA NA NA NA NA NA NA NA NA/;
	}

	print O "$arr[0]\t$var\t$gt\t$tvc_info\n";

}
close IN;
close O;
