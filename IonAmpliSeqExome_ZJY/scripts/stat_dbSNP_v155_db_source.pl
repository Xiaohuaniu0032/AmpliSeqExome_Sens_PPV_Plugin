use strict;
use warnings;

my ($dbSNP_file) = @ARGV;

my $ref_freq_cutoff = 0.1; # ref freq <= cutoff
my %db_item_count; # 统计每个数据库符合频率要求的INDEL数量
#my %db_item_in_bed; # 统计每个数据库在bed区间中的INDEL数量

my %db_list;
open VCF, "gunzip -dc $dbSNP_file |" or die;
while (<VCF>){
	next if (/^\#/);
	next if /VC=SNV/; # skip SNV
	my @arr = split /\t/;
	my $info = $arr[7]; # INFO信息列
	my @info = split /\;/, $info;
	for my $info (@info){
		if ($info =~ /^FREQ=/){
			my $db_info = $info;
			$db_info =~ s/^FREQ=//;
			my @db_info = split /\|/, $db_info;
			for my $db (@db_info){
				my @db = split /\:/, $db;
				my $db_name = $db[0];
				$db_list{$db_name} += 1;
				my @freq = split /\,/, $db[1];
				my $ref_freq = $freq[0];
				next if ($ref_freq eq ".");
				if ($ref_freq <= $ref_freq_cutoff){
					$db_item_count{$db_name} += 1;
				}
			}
		}
	}
}
close VCF;


my @db_list = keys %db_list;

# 输出整体数量统计
print "each db total indel line\n";

for my $db (@db_list){
	my $n;
	if (exists $db_list{$db}){
		$n = $db_list{$db};
	}else{
		$n = 0;
	}
	print "$db\: $n\n";
}

print "each db ref freq < cutoff indel line\n";
# 输出符合频率要求的数量统计
for my $db (@db_list){
	my $n;
	if (exists $db_item_count{$db}){
		$n = $db_item_count{$db};
	}else{
		$n = 0;
	}
	print "$db\: $n\n";
}
