use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

my ($TSVC_variants_vcf_file,$depth_file,$fasta,$sample_name,$outdir);

GetOptions(
	"vcf:s"  => \$TSVC_variants_vcf_file,             # Need
	"d:s"    => \$depth_file,                         # Need
	"fa:s"   => \$fasta,                              # Need
	"s:s"    => \$sample_name,                        # Need
	"od:s"   => \$outdir,                             # Need
	) or die "unknown args\n";

# check args
if (not defined $TSVC_variants_vcf_file || not defined $fasta || not defined $sample_name || not defined $outdir){
	die "please check your args\n";
}


my $gold_vcf_file = "$Bin/indel/YH-indel.vcf";
my $bcftools_bin = "$Bin/bcftools/bcftools";


# process steps
# 1. bcftools norm
# 2. remove 0/0 and ./. genotype call
# 3. filter by QUAL
# 4. stat indel's sensitivity and PPV according YH-indel.vcf

my $runsh = "$outdir/run\_$sample_name\.sh";
open O, ">$runsh" or die;


### bcfnorm indel标准化
### indel left align
### indel unify presentation

	# see https://samtools.github.io/bcftools/bcftools.html#norm for detail.

	# -m:split multiallelics (-) or join biallelics (+)
	# -c:check REF alleles and exit (e), warn (w), exclude (x), or set (s)

my $norm_vcf = "$outdir/$sample_name\.TSVC_variants.bcfnorm.vcf";
my $cmd = "export LD_LIBRARY_PATH=$Bin/bcftools/lib/x86_64-linux-gnu";
print O "$cmd\n";
$cmd = "$bcftools_bin norm -f $fasta -m - -c w $TSVC_variants_vcf_file >$norm_vcf";
print O "$cmd\n\n";


# 拆分MNP
my $split_mnp = "$outdir/$sample_name\.TSVC_variants.bcfnorm.splitMNP.vcf";
$cmd = "perl $Bin/Split_MNP.pl $norm_vcf $split_mnp >$outdir/$sample_name\.MNP.xls";
print O "$cmd\n\n";


# 检查重复变异位点
my $dup_var = "$outdir/$sample_name\.Dup.Vars.xls";
$cmd = "perl $Bin/Check_Dup_Vars_In_bcfnorm_splitMNP_vcf.pl $split_mnp $dup_var";
print O "$cmd\n\n";


# 去除重复的变异位点
my $norm_rmdup_vcf = "$outdir/$sample_name\.TSVC_variants.bcfnorm.splitMNP.rmdup.vcf";
$cmd = "perl $Bin/Remove_Dup_Vars_From_bcfnorm_splitMNP_vcf.pl $dup_var $split_mnp $norm_rmdup_vcf";
print O "$cmd\n\n";


# 删除 0/0 and ./. genotype call
my $called_vcf = "$outdir/$sample_name\.TSVC_variants.bcfnorm.splitMNP.rmdup.pass_gt_filter.vcf";
$cmd = "perl $Bin/scripts/filter_bcfnorm_vcf.pl $norm_rmdup_vcf $called_vcf";
print O "$cmd\n\n";


#检查flow矫正问题
$cmd = "perl $Bin/Check_TVC_Flow_Problem.pl $norm_rmdup_vcf $outdir/$sample_name\.Flow.Problem.txt";
print O "$cmd\n\n";


# 统计INDEL灵敏度和PPV
# three output file
my $Sens_file = "$outdir/$sample_name\.Sensitivity.xls";
my $PPV_file  = "$outdir/$sample_name\.PPV.xls";
my $Sens_PPV_Summary_file = "$outdir/$sample_name\.Sens_PPV_Summary.xls";

$cmd = "perl $Bin/scripts/Stat_Sensitivity.pl $called_vcf $gold_vcf_file $sample_name $Sens_file $Sens_PPV_Summary_file";
print O "$cmd\n\n";

# PPV
my $YH_27M_BED_file = "$Bin/YH_info/YH.bed"; # 27200236bp
$cmd = "perl $Bin/scripts/Stat_PPV.pl $called_vcf $YH_27M_BED_file $gold_vcf_file $PPV_file $Sens_PPV_Summary_file";
print O "$cmd\n\n";


# 检查灵敏度细节
my $Sens_TVC_detail_outfile = "$outdir/$sample_name\.TVC.Info.Sens.xls";
$cmd = "perl $Bin/scripts/Check_Sens_TVC_Detail.pl $Sens_file $norm_vcf $Sens_TVC_detail_outfile";
print O "$cmd\n\n";

# 检查PPV细节
my $PPV_TVC_detail_outfile  = "$outdir/$sample_name\.TVC.Info.PPV.xls";	
$cmd = "perl $Bin/scripts/Check_PPV_TVC_Detail.pl $PPV_file $PPV_TVC_detail_outfile";
print O "$cmd\n\n";

# 输出PPV MLLD/RBI.
#my $tp_fp_distri = "$outdir/$sample_name\.MLLD.RBI.plot.txt";
#$cmd = "perl $Bin/Classify_FP_by_MLLD_RBI.pl $PPV_TVC_detail_outfile $tp_fp_distri";
#print O "$cmd\n\n";

# 画图检查FP位点MLLD/RBI分布
#print O "cd $outdir\n";
#$cmd = "Rscript $Bin/TP_FP_MLLD_RBI.R $tp_fp_distri $sample_name";
#print O "$cmd\n\n";

# 输出热点DP/FDP等深度信息
my $depth_summary_file = "$outdir/$sample_name\.HS.InDel.Depth.Summary.xls";
$cmd = "perl $Bin/scripts/HS_InDel_Depth_Summary.pl $Sens_TVC_detail_outfile $depth_summary_file";
print O "$cmd\n\n";

# 总结NOCALL位点原因
my $NoCall_summary_file = "$outdir/$sample_name\.HS.InDel.NoCall.Reason.Summary.xls";
$cmd = "perl $Bin/scripts/HS_InDel_NoCall_Reason_Summary.pl $Sens_TVC_detail_outfile $NoCall_summary_file";
print O "$cmd\n\n";


# 统计SNP位点的灵敏度和PPV
my $snv_sens_outfile = "$outdir/$sample_name\.snv.sens.xls"; # 中间文件
my $snv_ppv_outfile  = "$outdir/$sample_name\.snv.ppv.xls";  # 中间文件
my $snv_summary_outfile  = "$outdir/$sample_name\.snv.sens.ppv.summary.xls";

my $gold_vcf = "$Bin/YH_info/YH.vcf";        # YH 27M 金标准SNV位点
my $bed      = "$Bin/YH_info/YH.bed";        # YH 27M BED文件

$cmd = "perl $Bin/scripts/Stat_SNV_Sens_PPV/cal_snv_sens_ppv.pl $gold_vcf $called_vcf $bed $snv_sens_outfile $snv_ppv_outfile >$snv_summary_outfile";
print O "$cmd\n\n";


# 根据TVC depth.txt统计热点INDEL深度
#my $hs_depth_txt = "$outdir/$sample_name\.hs.depth.txt";
#$cmd = "perl $Bin/Check_Hotspot_Depth.pl $depth_file $sample_name $hs_depth_txt";
#print O "$cmd\n\n";

# 根据samtools depth查看SNV FN位点原始深度
#my $root_dir = dirname($outdir);
#my $snv_fn_depth = "$outdir/$sample_name\.SNV.FN.Depth.txt";
#$cmd = "perl $Bin/Check_SNP_FN_RawDepth.pl $root_dir/Target_Depth/$sample_name\.samtools.depth.txt $snv_sens_outfile $snv_fn_depth";
#print O "$cmd\n\n";


#修改chr命名,且对QUAL加500固定值
my $final_vcf = "$outdir/$sample_name\.TSVC_variants.final.vcf";
$cmd = "perl $Bin/Modify_Chr_Plus_Qual.pl $called_vcf $final_vcf";
print O "\# get final vcf for $called_vcf file\n";
print O "$cmd\n\n";
close O;

`chmod 755 $runsh`;