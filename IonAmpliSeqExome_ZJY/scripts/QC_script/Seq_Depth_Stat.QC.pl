use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use FindBin;

my ($bam,$fasta,$bed,$sample_name,$outdir);

GetOptions(
	"bam:s"  => \$bam,               # Need
	"fa:s"   => \$fasta,             # Need
	"b:s"    => \$bed,               # Need
	"n:s"    => \$sample_name,       # Need
	"od:s"   => \$outdir,            # Need
	) or die "unknown args\n";


# Some QC metrics
# 1) flagstat
# 2) target mean depth
# 3) mpileup <can check depth and variants>
# 4) 10X/20X base percentage

