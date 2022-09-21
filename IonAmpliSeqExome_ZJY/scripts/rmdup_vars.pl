use strict;
use warnings;
use File::Basename;

# TSVC_variants.vcf may contains some variants that appeared >=1 times

# less /data/fulongfei/analysis/fsz/agilent_capture_plus_ion_seq_WES/second_seq_2021-12-30/tvc_reanalysis_2021-1-9/chip1/TSVC_variants.vcf|grep "73020375"
# for G-> GCTC, TVC has two records for this pos
#chr11   73020375        .       G       GCTC    134.802 PASS    AF=0.406977;AO=0;DP=116;FAO=35;FDP=86;FDVR=10;FR=.;FRO=51;FSAF=13;FSAR=22;FSRF=21;FSRR=30;FWDB=-0.0304334;FXX=0.156847;HRUN=1;HS_ONLY=0;LEN=3;MLLD=280.027;OALT=CTC;OID=.;OMAPALT=GCTC;OPOS=73020376;OREF=-;PB=0.5;PBP=1;QD=6.26987;RBI=0.0304441;REFB=-0.0245511;REVB=-0.000809817;RO=113;SAF=0;SAR=0;SRF=48;SRR=65;SSEN=0;SSEP=0;SSSB=4.20179e-08;STB=0.525266;STBP=0.712;TYPE=ins;VARB=0.0398826;HS      GT:GQ:DP:FDP:RO:FRO:AO:FAO:AF:SAR:SAF:SRF:SRR:FSAR:FSAF:FSRF:FSRR       0/1:134:116:86:113:51:0:35:0.406977:0:0:48:65:22:13:21:30
#chr11   73020375        rs139105330     G       GCTC    31.2167 PASS    AF=0.402299;AO=33;DP=113;FAO=35;FDP=87;FDVR=10;FR=.;FRO=52;FSAF=13;FSAR=22;FSRF=22;FSRR=30;FWDB=-0.0294023;FXX=0.147044;HRUN=1;HS_ONLY=0;LEN=3;MLLD=276.267;OALT=CTC;OID=rs139105330;OMAPALT=GCTC;OPOS=73020376;OREF=-;PB=0.5;PBP=1;QD=1.43525;RBI=0.0294091;REFB=-0.0242663;REVB=-0.000631493;RO=74;SAF=12;SAR=21;SRF=30;SRR=44;SSEN=0;SSEP=0;SSSB=-0.0522634;STB=0.532485;STBP=0.65;TYPE=ins;VARB=0.0406796;HS    GT:GQ:DP:FDP:RO:FRO:AO:FAO:AF:SAR:SAF:SRF:SRR:FSAR:FSAF:FSRF:FSRR       0/1:31:113:87:74:52:33:35:0.402299:21:12:30:44:22:13:22:30

# select var with large QUAL
# if top1 and top2 QUAL is equal, then skip this var (will not affect Sensitivity and PPV)

my ($tsvc_vcf,$outfile) = @ARGV;

my %tvc_vars;
my @vars_dup;

open O, ">$outfile" or die;

my $od = dirname($outfile);
my $rm_log = "$od/rm.dup.log";
open LOG, ">>$rm_log" or die;

open IN, "$tsvc_vcf" or die;
while (<IN>){
	chomp;
	if (/^\#/){
		#print O "$_\n";
		next;
	}
	next if (/^$/); # skip blank line
	my @arr = split /\t/;
	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	push @{$tvc_vars{$var}}, $arr[5];
	push @vars_dup, $var;
}
close IN;

# get uniq vars
my %var_uniq;
my @var_uniq; # by tvc var order

for my $var (@vars_dup){
	if (!exists $var_uniq{$var}){
		push @var_uniq, $var;
		$var_uniq{$var} = 1;
	}
}

# foreach @var_uniq, remove dup tvc vars
my %var_large_qual; # var with large qual
my %dup_vars; # save dup vars
my %skip_vars;

for my $var (@var_uniq){
	my @qual = @{$tvc_vars{$var}};
	#print "$var\t@qual\n";
	my $qual_num = scalar(@qual);
	if ($qual_num > 1){
		# dup vars
		$dup_vars{$var} = 1;

		# check top1 and top2 qual

		my @qual_sort = sort {$b <=> $a} (@qual);
		print LOG "$var\t@qual_sort\n";

		my $top1 = $qual_sort[0];
		my $top2 = $qual_sort[1];

		if ($top1 == $top2){
			$skip_vars{$var} = 1;
		}else{
			$var_large_qual{$var} = $top1;
		}
	}
}

# filter TSVC VCF


my %dup_flag;
open IN, "$tsvc_vcf" or die;
while (<IN>){
	chomp;
	if (/^\#/){
		print O "$_\n";
		next;
	}
	next if (/^$/); # skip blank line
	my @arr = split /\t/;
	my $qual = $arr[5];

	my $var = "$arr[0]\t$arr[1]\t$arr[3]\t$arr[4]"; # chr/pos/ref/alt
	if (exists $skip_vars{$var}){
		# skip this var
		print LOG "[Skip for this var has >= 3 same records] => \$_\n";
		next;
	}

	if (exists $dup_vars{$var}){
		#print "Dup vars: $var\n";
		if (!exists $dup_flag{$var}){
			my $large_qual = $var_large_qual{$var};
			#print "$var\t$qual\t$large_qual\n";
			if ($qual == $large_qual){
				# keep this var
				print O "$_\n";
				$dup_flag{$var} = 1;
				print LOG "[Dup vars, has larger QUAL, will be keeped] => $_\n";
			}else{
				print LOG "[Dup vars, but has small QUAL, will be skipped] => $_\n";
			}
		}else{
			print LOG "[Dup vars, but has small QUAL, will be skipped] => $_\n";
		}
	}else{
		print O "$_\n";
	}
}
close IN;
close O;
close LOG;