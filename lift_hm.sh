#!/bin/bash -l

while read path_line; do

 vcf=$(basename $path_line .vcf.gz)

  sbatch --export=input=$path_line --job-name=lift_$vcf --output=$vcf.out --cpus-per-task=16 --mem=90G --time=40:00:00 picard_lift_2.25.sbatch;
  sleep 1;

done < ARIC_paths_TOPMed_GR38.txt    