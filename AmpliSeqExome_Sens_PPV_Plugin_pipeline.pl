use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;


my ($plugin_result_dir,$fasta,$outdir) = @ARGV;


my @vcf = glob "$plugin_result_dir/*/TSVC_variants.vcf";

for my $vcf (@vcf){
	my $d = dirname($vcf);
	my $barcode = basename($d); # IonXpress_017

	if (!-d "$outdir/$barcode"){
		`mkdir $outdir/$barcode`;
	}

	print "Input vcf is: $vcf\n";
	my $depth_txt = "$d/depth.txt";
	my $cmd = "perl $Bin/IonAmpliSeqExome_ZJY/Stat_Sensitivity_PPV_Main.pl -vcf $vcf -d $depth_txt -fa $fasta -s $barcode -od $outdir/$barcode";
	print "CMD is: $cmd\n";
	system($cmd);


	print "Start process $barcode ...\n";
	#`sh $outdir/$barcode/run\_$barcode\.sh`;
	print "End process $barcode ...\n";
}

