vcf='YH-indel.vcf'
fa='/data/fulongfei/database/ref/hg19/hg19.fasta'

# -a perform left-alignment of indels
# -s do not filter out block substitution hotspots
# -d output left-aligned hotspots in BED format

tvcutils prepare_hotspots -v $vcf -r $fa -a -s -d YH-indel.bed


less YH-indel.vcf|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5}' >hs.list.check.IGV.xls
