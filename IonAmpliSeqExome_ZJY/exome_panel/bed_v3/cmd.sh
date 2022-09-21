less AmpliSeqExome.20141113.Plus_WG_IAD217223_20210922.designed.bed |awk 'NR>1'|awk '{print $1"\t"$2"\t"$3}' >AmpliSeqExome.20141113.Plus_WG_IAD217223_20210922.designed.Col3.bed
cat AmpliSeqExome.20141113.Plus_WG_IAD217223_20210922.designed.Col3.bed YH.bed >AmpliSeqExome.unmerged.bed
