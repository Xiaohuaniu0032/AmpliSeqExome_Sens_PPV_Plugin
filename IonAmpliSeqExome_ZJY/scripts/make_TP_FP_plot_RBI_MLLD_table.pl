use strict;
use warnings;

my ($ppv_tvc_info_file,$outfile) = @ARGV;

open O, ">$outfile" or die;
print O "Var\tQUAL\tMLLD\tRBI\tAF\tType\n";

open IN, "$ppv_tvc_info_file" or die;
<IN>;
while (<IN>){
	chomp;
	next if (/NA/); # some var in TVC do not have MLLD/RBI/ 
	my @arr  = split /\t/;
	my $var  = $arr[1];
	my $QUAL = (split /\=/, $arr[3])[1];
	my $MLLD = (split /\=/, $arr[4])[1];
	my $RBI  = (split /\=/, $arr[6])[1];
	my $AF   = (split /\=/, $arr[-1])[1];
	my $Type = $arr[0];
	print O "$var\t$QUAL\t$MLLD\t$RBI\t$AF\t$Type\n"; 
}
close IN;
close O;