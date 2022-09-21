use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my $YH27Mbed = "$Bin/YH_info/YH.bed";
my $Amplibed = "$Bin/exome_panel/bed_v2/merged/AmpliSeqExome.20141113.Plus_WG_IAD217223_20210922.designed.bed";

my ($outfile) = @ARGV;

open O, ">$outfile" or die;
print O "chr\tstart\tend\n";

# check YH 27M region that not covered by Ampli bed

my %Ampli_pos;

#chr1    68928   69134
#chr1    69212   69810
#chr1    861310  861531
#chr1    865391  865813
#chr1    866364  866559


open IN, "$Amplibed" or die;
while (<IN>){
	chomp;
	next if /^$/;
	my @arr = split /\t/;
	my $chr = $arr[0];
	#next if ($chr ne "chr1"); # for test
	my $start = $arr[1] + 1;
	my $end = $arr[2];

	for my $pos ($start..$end){
		$Ampli_pos{$chr}{$pos} = 1;
	}
}
close IN;


my %not_covered;

open IN, "$YH27Mbed" or die;
while (<IN>){
	chomp;
	next if /^$/;
	my @arr = split /\t/;
	my $chr = $arr[0];
	#next if ($chr ne "chr1"); # for test
	my $start = $arr[1] + 1;
	my $end = $arr[2];

	my @not_covered;
	for my $pos ($start..$end){
		if (!exists $Ampli_pos{$chr}{$pos}){
			push @not_covered, $pos;
		}
	}


	my $not_covered_pos_num = scalar(@not_covered);
	next if ($not_covered_pos_num == 0);

	# merge \@not_covered
	my @segments;
	
	my $first = shift @not_covered;
	push @segments, $first;
	
	for my $pos (@not_covered){
		my $last_seg = $segments[-1];
		if ($last_seg =~ /\_/){
			my $last_seg_last_pos = (split /\_/, $last_seg)[-1];
			if ($pos - $last_seg_last_pos == 1){
				# 1 2 3
				pop @segments;
				my $new_seg = $last_seg."_".$pos;
				push @segments, $new_seg;
			}else{
				push @segments, $pos;
			}
		}else{
			my $last_seg_last_pos = $last_seg;
			if ($pos - $last_seg_last_pos == 1){
				pop @segments;
				my $new_seg = $last_seg.'_'.$pos;
				push @segments, $new_seg;
			}else{
				push @segments, $pos;
			}
		}
	}

	for my $seg (@segments){
		if ($seg =~ /\_/){
			my @pos = split /\_/, $seg;
			print O "$chr\t$pos[0]\t$pos[-1]\n";
		}else{
			print O "$chr\t$seg\t$seg\n";
		}
	}
}
close IN;
close O;
