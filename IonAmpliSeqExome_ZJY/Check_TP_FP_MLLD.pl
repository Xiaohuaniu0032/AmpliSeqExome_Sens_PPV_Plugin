use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

# chip1_017.PPV.xls

my ($input_file,$output_file) = @ARGV;

open IN, "$input_file" or die;
while (<IN>){
	chomp;
	my @arr = split /\t/, $_;
	if (/MLLD/){
		my $call_res = $arr[0]; # TP / FP
		my $info = $arr[8];
		my @info = split /\;/, $info;
		
		my $MLLD;
		for my $item (@info){
			if ($item =~ /MLLD/){
				$MLLD = (split /\=/, $item)[1];
				last;
			}
		}

		my $chr = $arr[1];
		my $pos = $arr[2];
		my $ref = $arr[4];
		my $alt = $arr[5];

		print "$call_res\t$chr\t$pos\t$ref\t$alt\t$MLLD\n";
	}
}
close IN;