dbsnp='/data/fulongfei/database/annot/dbSNP/hg19/2021-5-25/GCF_000001405.25.gz'
perl prepare_indel_hs_vcf.pl $dbsnp /data/fulongfei/git_repo/wes_cap_ion/bed_files/merge_bed/YH_plus_Agilent_V6.bed $PWD high_pop_alt_freq_from_dbSNP.InDel.vcf

#nohup perl stat_dbSNP_v155_db_source.pl /data/fulongfei/database/annot/dbSNP/hg19/2021-5-25/GCF_000001405.25.gz >db_stat.freq.10pct.xls &
