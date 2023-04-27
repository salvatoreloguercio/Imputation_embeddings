#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
##SBATCH --cpus-per-task=20
##SBATCH --mem=150G
##SBATCH --partition=highmem
######SBATCH --partition=shared
##SBATCH --time=340:00:00

module load python/3.8.3
module load samtools
module load java #beagle
#module load picard
#module load gatk

#module load gatk/4.1.9.0

#indir=/mnt/stsi/stsi3/External/TOPMed/TOPMed.ARIC.WholeGene.phs001211.c1.HMB-IRB/phs001211.v3.p2/RootStudyConsentSet_phs001211.TOPMed_WGS_ARIC.v3.p2.c1.HMB-IRB/GenotypeFiles/phg001313.v1.TOPMed_WGS_ARIC_v3.genotype-calls-vcf.WGS_markerset_grc38.c1.HMB-IRB
#for i in {1..22}; do sbatch --export=input=$indir/ARIC_phs001211_TOPMed_WGS_freeze.8.chr$i.hg38.c1.vcf.gz --job-name=picard_lift_ARIC_$i picard_lift_2.25.sbatch; sleep 1; done
#sbatch --export=input=my_vcf.vcf.gz --job-name=picard_lift_my_vcf picard_lift_2.25.sbatch

#echo "workdir: $PBS_O_WORKDIR"
#cd $PBS_O_WORKDIR

echo "workdir: $SLURM_SUBMIT_DIR"
cd $SLURM_SUBMIT_DIR


start=`date +%s`

tmpdir=/mnt/stsi/stsi6/Internal/TOPmed/tmp/picard_${SLURM_JOBID}
refdir=/mnt/stsi/stsi5/raqueld/picard_utils

mkdir $tmpdir

#old picard has a bug with Grch37->38 chain reading, new picard is now part of gatk
#picard="java -Xmx20G -jar /opt/applications/picard/2.1.0/bin/picard.jar"
#picard="java -Xmx20G -jar /opt/applications/picard/2.9.2/bin/picard.jar"
#picard="java -Xmx20G -jar $HOME/bin/picard.jar"
#picard="java -Xmx60G -XX:ParallelGCThreads=4 -jar $HOME/bin/picard.jar"
#trying to solve No Space Left on Device issue:
picard="java -Xmx60G -XX:ParallelGCThreads=4 -Djava.io.tmpdir=$tmpdir -jar /gpfs/home/raqueld/bin/picard.jar"

#provided by liftover (golden path)
#chain=hg19ToHg38.over.chain
#chain from ucsd genome browser
#chain="GRCh37_to_hg38.chain"
#chain provided by picard/gatk
#chain="b37ToHg38.over.chain"
chain="$refdir/hg38ToHg19.over.chain"


#fasta="GRCh38_full_analysis_set_plus_decoy_hla.fa"
#fasta="/mnt/stsi/stsi0/raqueld/1000G/human_g1k_v37.fasta"
#fasta="human_g1k_v37.relabel.fasta"
fasta="$refdir/hg19.fa.gz"

name=$(basename $input | sed -e 's/\.vcf\.gz$//g' | sed -e 's/\.vcf$//g')

output="$name.hg19.vcf"
reject="$name.hg19_rejected_variants.vcf"

#if [ ! -f $(basename $input) ]; then
#    bcftools annotate --rename-chrs ${chr}_chr_names.txt $input -Oz -o $(basename $input) $input && tabix -p vcf -f $(basename $input)
#fi

#cmd="$picard LiftoverVcf I=$(basename $input) O=2.25_$output C=$chain REJECT=2.25_$reject R=$fasta"
#cmd="$picard LiftoverVcf I=$(basename $input) O=2.25_$output C=$chain REJECT=2.25_$reject R=$fasta MAX_RECORDS_IN_RAM=2500"
#cmd="gatk LiftoverVcf -I $(basename $input) -O $output --CHAIN $chain --REJECT ${reject} -R $fasta"

cmd="$picard LiftoverVcf I=$input O=$output C=$chain REJECT=$reject R=$fasta MAX_RECORDS_IN_RAM=2500"

echo $cmd

$cmd

echo "Compressing output...."

bgzip -c ${output} --threads 16 > ${output}.gz
tabix -p vcf -f ${output}.gz

bgzip -c ${reject} --threads 16 > ${reject}.gz
tabix -p vcf -f ${reject}.gz

echo "Removing tmp files...."

rm ${output}
rm ${reject}
rm -rf $tmpdir

end=`date +%s`

runtime=$((end-start))

echo "Total runtime using 16 cores, 90GB RAM: ${runtime}"






