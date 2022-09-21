use strict;
use warnings;

my ($chip1_sens_tvc_info,$chip2_sens_tvc_info,$outfile) = @ARGV;


# get all vars
my %var;
my @var_uniq_by_order;
my %var_flag;

open IN, "$chip1_sens_tvc_info" or die;
while (<IN>){
	chomp;
	next if (/^\#/);
	next if (/NA/);
	my @arr = split /\t/;
	my $var = $arr[1];
	$var{$var} = 1;


	if (exists $var_flag{$var}){
		next;
	}else{
		push @var_uniq_by_order, $var;
		$var_flag{$var} = 1;
	}
}
close IN;

open IN2, "$chip2_sens_tvc_info" or die;
while (<IN2>){
	chomp;
	next if (/^\#/);
	next if (/NA/);
	my @arr = split /\t/;
	my $var = $arr[1];
	$var{$var} = 1;

	if (exists $var_flag{$var}){
		next;
	}else{
		push @var_uniq_by_order, $var;
		$var_flag{$var} = 1;
	}
}
close IN2;





# read chip1 info
my %tvc_chip1;
my ($chip1_called_num,$chip1_notcall_num) = (0,0);

open IN, "$chip1_sens_tvc_info" or die;
while (<IN>){
	chomp;
	next if (/^\#/);
	next if (/NA/);
	my @arr = split /\t/;
	my $var = $arr[1];
	my $tvc_info = "$arr[3]\;$arr[4]\;$arr[5]\;$arr[6]\;$arr[8]\;$arr[9]\;$arr[10]\;$arr[11]\;$arr[12]\;$arr[13];$arr[14]"; # QUAL/MLLD/STB/RBI/FR/AO/FAO/DP/FDP/AF/GT
	$tvc_chip1{$var} = "$tvc_info\t$arr[0]";

	if ($arr[0] eq "Called"){
		$chip1_called_num += 1;
	}else{
		$chip1_notcall_num += 1;
	}
}
close IN;


# read chip2 info
my %tvc_chip2;
my ($chip2_called_num,$chip2_notcall_num) = (0,0);

open IN, "$chip2_sens_tvc_info" or die;
while (<IN>){
	chomp;
	next if (/^\#/);
	next if (/NA/);
	my @arr = split /\t/;
	my $var = $arr[1];
	my $tvc_info = "$arr[3]\;$arr[4]\;$arr[5]\;$arr[6]\;$arr[8]\;$arr[9]\;$arr[10]\;$arr[11]\;$arr[12]\;$arr[13]\;$arr[14]"; # QUAL/MLLD/STB/RBI/FR/AO/FAO/DP/FDP/AF/GT
	$tvc_chip2{$var} = "$tvc_info\t$arr[0]";

	if ($arr[0] eq "Called"){
		$chip2_called_num += 1;
	}else{
		$chip2_notcall_num += 1;
	}
}
close IN2;



# 输出overlap
my $both_called_num = 0;

for my $var (@var_uniq_by_order){
	if (exists $tvc_chip1{$var} and exists $tvc_chip2{$var}){
		my $tvc_c1 = (split /\t/, $tvc_chip1{$var})[1];
		my $tvc_c2 = (split /\t/, $tvc_chip2{$var})[1];

		if ($tvc_c1 eq "Called" and $tvc_c2 eq "Called"){
			$both_called_num += 1;
		}
	}
}

open O, ">$outfile" or die;

print O "###check called tp overlap\n";
print O "chip1_called\tchip2_called\tidentical\tidentical/Chip1\tidentical/Chip2\tidentical_freq_correlation\n";

my $iden_chip1 = sprintf "%.2f", $both_called_num / $chip1_called_num * 100;
my $iden_chip2 = sprintf "%.2f", $both_called_num / $chip2_called_num * 100;

print O "$chip1_called_num\t$chip2_called_num\t$both_called_num\t$iden_chip1\t$iden_chip2\tNA\n";
print O "\n\n";



# 输出详细的比对信息
print O "\#If_Both_Call\tvar\tchip1_call\tchip2_call\tchip1_tvc\tchip2_tvc\n";

# for each var, check its result in chip1 and chip2
for my $var (@var_uniq_by_order){
	
	my ($call_chip1, $call_chip2);
	my ($tvc_chip1,  $tvc_chip2);
	
	my $if_both_call;

	if (exists $tvc_chip1{$var}){
		my $res_chip1 = $tvc_chip1{$var};
		my @res_chip1 = split /\t/, $res_chip1;
		
		$call_chip1 = $res_chip1[1];
		$tvc_chip1  = $res_chip1[0];
	}else{
		$call_chip1 = "NA";
		$tvc_chip1  = "NA";
	}

	if (exists $tvc_chip2{$var}){
		my $res_chip2 = $tvc_chip2{$var};
		my @res_chip2 = split /\t/, $res_chip2;

		$call_chip2 = $res_chip2[1];
		$tvc_chip2  = $res_chip2[0];
	}else{
		$call_chip2 = "NA";
		$tvc_chip2  = "NA";
	}

	if ($call_chip1 eq $call_chip2){
		$if_both_call = "SameCall";
	}else{
		$if_both_call = "NotSame";
	}

	print O "$if_both_call\t$var\t$call_chip1\t$call_chip2\t$tvc_chip1\t$tvc_chip2\n";
}

close O;


