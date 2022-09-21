use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;


# 第一步: 运行variantCaller [可选]
# 第二步: 统计Sens/PPV

my ($bam,$vcf,$depth_file,$fasta,$sample_name,$outdir);

GetOptions(
	"bam:s"  => \$bam,                                # Optional
	"vcf:s"  => \$vcf,                                # Optional
	"d:s"    => \$depth_file,                         # Same as vcf
	"fa:s"   => \$fasta,                              # Need
	"s:s"    => \$sample_name,                        # Need
	"od:s"   => \$outdir,                             # Need
	) or die "unknown args\n";



if (!-d "$outdir/$sample_name/variantCaller"){
	`mkdir -p $outdir/$sample_name/variantCaller`;
}

if (!-d "$outdir/$sample_name/Sens_PPV"){
	`mkdir -p $outdir/$sample_name/Sens_PPV`;
}

if (!-d "$outdir/$sample_name/Target_Depth"){
	`mkdir -p $outdir/$sample_name/Target_Depth`;
}



#print "$bam\n";
#print "$vcf\n";

`perl $Bin/run_variantCaller.pl $bam $sample_name $fasta $outdir/$sample_name/variantCaller`;
`perl $Bin/Stat_Sensitivity_PPV_Main.pl -vcf $vcf -d $depth_file -fa $fasta -s $sample_name -od $outdir/$sample_name/Sens_PPV`;




my $sambamba_sh = "$outdir/$sample_name/Target_Depth/run_sambamba.sh";
open O, ">$sambamba_sh" or die;
my $target_depth = "$outdir/$sample_name/Target_Depth/$sample_name.region.depth.txt";
print O "$Bin/bin/sambamba-0.8.1-linux-amd64-static depth region -L $Bin/exome_panel/bed_v3/merged/AmpliSeqExome.merged.bed -t 12 $bam >$target_depth\n\n";
close O;
`chmod 755 $sambamba_sh`;



my $samtools_sh = "$outdir/$sample_name/Target_Depth/run_samtools_depth.sh";
open O, ">$samtools_sh" or die;
my $samtools_depth = "$outdir/$sample_name/Target_Depth/$sample_name\.samtools.depth.txt";
my $bed = "$Bin/exome_panel/bed_v3/merged/AmpliSeqExome.merged.bed";
print O "/usr/bin/samtools depth -a -b $bed $bam >$samtools_depth\n";
close O;
`chmod 755 $samtools_sh`;




