#!/usr/bin/env bash
#
#SBATCH -J RunMoments # A single job name for the array
#SBATCH -c 2
#SBATCH -N 1 # on one node
#SBATCH -t 24:00:00 #<= this may depend on your resources
#SBATCH --mem=120G #<= this may depend on your resources
#SBATCH -o ./moments.%A_%a.out # Standard output
#SBATCH -e ./moments.%A_%a.err # Standard error
#SBATCH -p largemem
#SBATCH -A jcbnunez

echo "began at"  `date`

#Load conda module
module load anaconda/2020.11-py3.8

#Activate moments kernell
source activate moments_kern

#Load the metadata object into memory
metadata= <...> #Address to the metadata. What is this? see below:

#The metadata file is as follows:
# A file with 3 columns and a header
# Separated by tabs
#Pair_names \t address_to_fs \t L
#At1|At2	   /file/At12.fs   1200000	

#Pair_names=> the names of the two pools being considered. Separated by a predictable delimiter like "|" (do not use "_")!!!
#address_to_fs=> the address of the file containing the 2D SFS
#L => The number of sites from which the SFS was derived. IMPORTANT: This number must be an integer. No scientific notation allowed. 

#===> Want to fix SLURM_ARRAY_TASK_ID? this is useful for debugging <====
#=# SLURM_ARRAY_TASK_ID=1

#Mining the metadata file

Pair=$( cat $metadata  | sed '1d' | sed "${SLURM_ARRAY_TASK_ID}q;d" | awk -F "\t" '{ print $1 }' ) 
SFS=$( cat $metadata  | sed '1d' | sed "${SLURM_ARRAY_TASK_ID}q;d" | awk -F "\t" '{ print $2 }' ) 
L=$( cat $metadata  | sed '1d' | sed "${SLURM_ARRAY_TASK_ID}q;d" | awk -F "\t" '{ print $3 }' ) 

echo "Now Processing" $Pair
echo "Now Loading" $SFS "=> where" $Pair "SFS is located"
echo $Pair "has an L parameter of" $L "bp"

#Run Moments 
# this script takes 4 arguments
#fs_file = sys.argv[1] ==> location of SFS i.e. -> $SFS
#L_file = sys.argv[2] ==> L param i.e. -> $L
#iterations = sys.argv[3] ==> number of runs ... a number
#pair_name = sys.argv[4] ==> name of the pair -> $Pair

python 2.2.MomentsCode.py \
$SFS \
$L \
1000 \
Pair


#De-Activate moments kernell
conda deactivate

#Print the time
echo "ended at"  `date`