use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my ($samtools_depth_file,$snv_sens_file,$outfile) = @ARGV;

# chip1.samtools.depth.txt
# chr1    68929   18
# chr1    68930   18
# chr1    68931   18
# chr1    68932   18
# chr1    68933   18


open O, ">$outfile" or die;
print O "FN\tchr\tpos\tdepth\n";

my %False_Neg_Vars;
open IN, "$snv_sens_file" or die;
<IN>;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	if ($arr[0] eq "NotCalled"){
		my $var = "$arr[1]\t$arr[2]\t$arr[4]\t$arr[5]"; # chr/pos/ref/alt
		#$False_Neg_Vars{$var} = 1;
		my $POS = "$arr[1]\t$arr[2]"; # chr/pos
		$False_Neg_Vars{$POS} = 1; # 记录FN位点
	}
}
close IN;

open IN, "$samtools_depth_file" or die;
while (<IN>){
	chomp;
	my @arr = split /\t/;
	my $POS = "$arr[0]\t$arr[1]";
	if (exists $False_Neg_Vars{$POS}){
		print O "FN\t$_\n";
	}
}
close IN;
close O;


