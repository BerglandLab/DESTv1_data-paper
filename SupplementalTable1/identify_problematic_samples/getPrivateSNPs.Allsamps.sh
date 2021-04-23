#!/usr/bin/env bash
#
#SBATCH -J geoEndemicPoolSeq # A single job name for the array
#SBATCH --ntasks-per-node=2 # one core
#SBATCH -N 1 # on one node
#SBATCH --cpus-per-task=1 ### standard has 28 or 40 $SLURM_CPUS_PER_TASK
#SBATCH -t 5:00:00 # Running time of 1 hours
#SBATCH --mem 6G # Memory request of 8 GB
#SBATCH -p standard
#SBATCH --account berglandlab

# sbatch /scratch/aob2x/dest/data-paper/SupplementalTable1/identify_problematic_samples/getPrivateSNPs.Allsamps.sh
# sacct -j 18750850

module load bcftools

wd=/scratch/aob2x/dest/data-paper


bcftools view \
/project/berglandlab/DEST/vcf/dest.PoolSeq.SNAPE.NA.NA.10Nov2020.ann.vcf.gz | grep -v "#" | awk '{
npoly=0
nmissing=0
af=0
pops=""
if(length($5)==1) {
  for(i=10; i<=NF; i++) {
    split($i, sp, ":")
    if(sp[1]=="0/1") npoly++
    if(sp[1]=="0/1") pops=pops";"i-9
    if(sp[1]=="0/1") af=af"+"sp[5]
    if(sp[1]=="./.") nmissing++
    }
    if(npoly==1) print $1"\t"$2"\t"npoly"\t"nmissing"\t"$4"\t"$5"\t"pops"\t"af
  }
}' > /scratch/aob2x/SNAPE.AllSamps.0.001.delim
