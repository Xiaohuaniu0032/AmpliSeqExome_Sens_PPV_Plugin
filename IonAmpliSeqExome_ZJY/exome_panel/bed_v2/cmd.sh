pool_13='/data/fulongfei/git_repo/IonAmpliSeqExome_ZJY/exome_panel/plus_pool/WG_IAD217223.20210922.results/WG_IAD217223.20210922.designed.bed'

raw_bed='/data/fulongfei/git_repo/IonAmpliSeqExome_ZJY/exome_panel/AmpliSeqExome.20141113.designed.bed'

# modify raw bed
less $raw_bed | awk 'NR==1' >header
less $raw_bed | awk 'NR>1' | awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$7"\t"$8}' >AmpliSeqExome.20141113.designed.bed

# modify pool-13
less $pool_13 | awk 'NR>1' >WG_IAD217223.20210922.designed.bed

# make final bed
cat header AmpliSeqExome.20141113.designed.bed WG_IAD217223.20210922.designed.bed >AmpliSeqExome.20141113.Plus_WG_IAD217223_20210922.designed.bed



rm header
rm AmpliSeqExome.20141113.designed.bed
rm WG_IAD217223.20210922.designed.bed

