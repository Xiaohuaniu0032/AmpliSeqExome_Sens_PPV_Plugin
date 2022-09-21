use strict;
use warnings;

# 脚本目的:提取ref人群频率低于0.05的indel,用于评估indel的灵敏度和PPV.
# ref人群频率低于0.05,相当于突变的allele在几乎整个人群中都出现

# 请注意:有一些snv indel的人群频率,在不同的人群中会有较大的差异.
# 1) 先过滤1000genome常见突变
# 2) 统计特定数据库: Korea1K、GnomAD_exomes、ExAC、1000Genomes

my ($dbSNP_vcf,$cap_bed,$outdir,$out_vcf_name) = @ARGV;


my %target_pos;
open BED, "$cap_bed" or die;
while (<BED>){
	chomp;
	my @arr = split /\t/;
	my $sp = $arr[1] + 1;
	my $ep = $arr[2];
	for my $p ($sp..$ep){
		$target_pos{$arr[0]}{$p} = 1;
	}
}
close BED;

my %useful_chr;
my @nc_list = qw/NC_000001 NC_000002 NC_000003 NC_000004 NC_000005 NC_000006 NC_000007 NC_000008 NC_000009 NC_000010 NC_000011 NC_000012 NC_000013 NC_000014 NC_000015 NC_000016 NC_000017 NC_000018 NC_000019 NC_000020 NC_000021 NC_000022 NC_000023 NC_000024/;
# chr1-chr22,chrX,chrY
for my $item (@nc_list){
	$useful_chr{$item} = 1;
}

open O, ">$outdir/$out_vcf_name" or die;

my $ref_freq_cutoff = 0.05; # ref freq should <= cutoff [0.05]

my @db_list_to_check = qw/Korea1K GnomAD_exomes ExAC 1000Genomes/;
my %db_list_to_check; # 只统计特定数据库
$db_list_to_check{"Korea1K"} = 1;
$db_list_to_check{"GnomAD_exomes"} = 1;
$db_list_to_check{"ExAC"} = 1;
$db_list_to_check{"1000Genomes"} = 1;

print "Start to process dbSNP vcf db\n";
if ($dbSNP_vcf =~ /\.gz$/){
	open IN, "gunzip -dc $dbSNP_vcf |" or die;
}else{
	open IN, "$dbSNP_vcf" or die;
}

while (<IN>){
	chomp;
	next if /VC=SNV/; # skip SNV
	if (/^\#/){
		print O "$_\n";
	}else{
		# 检查坐标是否在BED区域
		# 替换染色体名 NC_000001.10 = > chr1
		my @arr = split /\t/;
		my $NC = (split /\./, $arr[0])[0]; # NC_000001.10
		next if (!exists $useful_chr{$NC});
		$NC =~ s/^NC_//;
		$NC =~ s/^0+//;
		my $chr_int = int($NC);
		my $chr;
		if ($chr_int <= 22){
			$chr = "chr".$chr_int;
		}elsif ($chr_int == 23){
			$chr = "chrX";
		}else{
			$chr = "chrY";
		}
		
		next if (!exists $target_pos{$chr}{$arr[1]}); # 跳过不在bed区间中的位点

		# check db records
		# FREQ=1000Genomes:0.5747,0.4253,.|TOMMO:0.9994,0.0005821,.|dbGaP_PopFreq:1,0,0;COMMON

		my $info = $arr[7]; # INFO信息列
		my @info = split /\;/, $info;
		for my $info (@info){
			#print "$info\n";
			if ($info =~ /^FREQ=/){
				# 检查FREQ信息
				#print "$info\n";
				next if ($info =~ /COMMON/); # 跳过常见突变
				# RS is a common SNP.
				# A common SNP is one that has at least one 1000Genomes population with a minor allele of frequency >= 1% and for which 2 or more founders contribute to that minor allele frequency.
				my $db_info = $info;
				$db_info =~ s/^FREQ=//;
				
				my $ref_freq;
				my $if_db_meet_freq = 0; #在该位点,有没有一个数据库,其ref人群频率满足cutoff

				if ($db_info =~ /\|/){
					# 包含多个数据库频率信息
					my @db_info = split /\|/, $db_info;
					for my $db (@db_info){
						my $db_name = (split /\:/, $db)[0];
						next if (!exists $db_list_to_check{$db_name});
						my $freq_info = (split /\:/, $db)[1];
						$ref_freq = (split /\,/, $freq_info)[0];
						next if ($ref_freq eq ".");
						if ($ref_freq <= $ref_freq_cutoff){
							$if_db_meet_freq += 1;
						}
					}
				}else{
					# 该位点只有一个db存在记录
					my $db_name = (split /\:/, $db_info)[0];
					next if (!exists $db_list_to_check{$db_name});

					my $freq_info = (split /\:/, $db_info)[1];
					$ref_freq = (split /\,/, $freq_info)[0];
					next if ($ref_freq eq ".");
					if ($ref_freq <= $ref_freq_cutoff){
						$if_db_meet_freq += 1;
					}
				}

				if ($if_db_meet_freq == 1){
					# 该位点至少有1个db记录,其ref人群频率满足阈值要求
					$arr[0] = $chr;
					my $val = join "\t", @arr;
					print O "$val\n"; # 替换染色体名称
				}
			}
		}
	}
}
close IN;
close O;
