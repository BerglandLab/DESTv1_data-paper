### libraries

library(genomalicious)
library(SeqArray)
library(foreach)
library(sp)
library(doMC)

registerDoMC(2)

args = commandArgs(trailingOnly=TRUE)

job=as.numeric(args[1])
popset=args[2]
dir= args[3]
Meta_dir=args[4]
DEST_gds_dir=args[5]

print(c(job,popset,dir,Meta_dir,DEST_gds_dir))

##########################################
#acting on the user input:
#1.Create output the directory
system(paste("mkdir", dir, sep = " "))

#2. Load the pairs data
pairs <- fread(popset)

#3. load DEST metadata
samps <- fread(paste(Meta_dir,"samps_10Nov2020.csv", sep = "/"))

#4. Load effective coverage
dep <- fread(paste(Meta_dir, "sequencingStats/rd.csv", sep = "/"))[auto==T]


#message(job)
#head(pairs)
pairs[job]


### open GDS file & make SNP table
if (pairs[job]$data_source=="PoolSNP") {
  #q(save="no")
  message("PoolSNP")
  genofile <- seqOpen(paste(DEST_gds_dir, "dest.PoolSeq.PoolSNP.001.50.10Nov2020.ann.gds", sep="/"))
  
} else if (pairs[job]$data_source=="SNAPE") {
  message("SNAPE")
  #genofile <- openfn.gds(paste("/project/berglandlab/DEST/gds/dest.PoolSeq.SNAPE.NA.NA.10Nov2020.ann.gds", sep=""))
  genofile <- seqOpen(paste(DEST_gds_dir ,"dest.PoolSeq.SNAPE.NA.NA.10Nov2020.ann.gds", sep="/"))
}


# make SNP table - old
message("making snp table")
snps.dt <- data.table(chr=seqGetData(genofile, "chromosome"),
                      pos=seqGetData(genofile, "position"),
                      variant.id=seqGetData(genofile, "variant.id"),
                      nAlleles=seqNumAllele(genofile),
                      missing=seqMissing(genofile, .progress=T))
## choose number of alleles
snps.dt <- snps.dt[nAlleles==2]

##### load premade SNP table
##  if (pairs[job]$data_source=="PoolSNP") {
##    #q(save="no")
##    message("load PoolSNP snp table")
##    load("/scratch/aob2x/moments_general/snp_table_PoolSNP.Rdata")
##
##  } else if (pairs[job]$data_source=="SNAPE") {
##    message("load SNAPE snp table")
##    load("/scratch/aob2x/moments_general/snp_table_SNAPE.Rdata")
##  }
##

### get polymorphism data
message("get poly")
setkey(snps.dt, chr)
seqSetFilter(genofile, sample.id=as.character(pairs[job, c("V1", "V2"), with=F]),
             variant.id=snps.dt[J(c("2L", "2R", "3L", "3R"))]$variant.id)


### get allele frequency data
ad <- seqGetData(genofile, "annotation/format/AD")
dp <- seqGetData(genofile, "annotation/format/DP")



### open GDS file & make SNP table
if (pairs[job]$data_source=="PoolSNP") {
  message("PoolSNP")
  dat <- ad$data/dp
  
} else if (pairs[job]$data_source=="SNAPE") {
  message("SNAPE")
  dat <- ad/dp
}

dim(dat)
rownames(dat) <- seqGetData(genofile, "sample.id")
dat <- t(dat)

### do we restrict data to a read-depth slice? -- This is now deprecated
##if(pairs$rd_filter[job]=="median_1sd") {
##  message("median_1sd")
##  med_rd <- apply(dp$data, 1, median, na.rm=T)
##  sd_rd <- apply(dp$data, 1, sd, na.rm=T)
##  
##  tf <- dp$data[1,]>= (med_rd[1]-sd_rd[1]) & dp$data[1,]<= (med_rd[1]+sd_rd[1]) &
##    dp$data[2,]>= (med_rd[2]-sd_rd[2]) & dp$data[2,]<= (med_rd[2]+sd_rd[2])
##  table(tf)
##  dat <- dat[tf,]
##  dim(dat)
##} else if(pairs$rd_filter[job]=="all") {
##  message("all")
tf<-TRUE
##  dim(dat)
##}


### Calculate Neff
### load average effective read depth
setkey(dep, sampleId)
setkey(samps, sampleId)
neff <- merge(dep[J(colnames(dat))], samps[J(colnames(dat))], by="sampleId")[,c("sampleId", "nFlies", "mu.25"), with=F]
neff[,ne:=round((2*nFlies*mu.25)/(2*nFlies+mu.25))]
neff[,ne:=floor(ne/2)] ### note, this is the number of diploid individuals...


#### integerize
#  dat.orig <- dat
#  dat[,1] <- round(dat[,1]*neff$ne[1])
#  dat[,2] <- round(dat[,2]*neff$ne[2])

### convert to format for genomalicious
dat <- as.data.table(dat)
dat[,locus:=seqGetData(genofile, "variant.id")[tf]]
dat[,ref:=seqGetData(genofile, "$ref")[tf]]
dat[,alt:=seqGetData(genofile, "$alt")[tf]]

datl <- melt(dat, id.vars=c("locus", "ref", "alt"))
setnames(datl, c("variable", "value"), c("POOL", "FREQ"))

datl <- merge(datl, neff[,c("sampleId", "ne")], by.x="POOL", by.y="sampleId")
datl[,FREQ:=1-FREQ]
datl <- na.omit(datl)


if(pairs$sfs_method[job]=="counts") {
  sfs_method="counts"
} else if(pairs$sfs_method[job]=="binom") {
  sfs_method="probs"
}
message(sfs_method)

dadi <- dadi_inputs_pools(
  datl,
  poolCol = "POOL",
  locusCol = "locus",
  refCol = "ref",
  altCol = "alt",
  freqCol = "FREQ",
  indsCol = "ne",
  poolSub = NULL,
  methodSFS = sfs_method
)
dadi <- na.omit(dadi) 

### Write dadi file

fn <- paste(dir,
            pairs[job]$data_source, ".",
            pairs[job]$sfs_method, ".",
            pairs[job]$V1, ".",
            pairs[job]$V2, ".",
            pairs[job]$popset,
            ".delim", sep="")

write.table(dadi,
            file=fn ,
            sep="\t", quote=F, row.names=F)


### Write metadata file
meta <- data.table(id=paste(c(paste(pairs[job,c("data_source", "sfs_method"), with=F], collapse="."), seqGetData(genofile, "sample.id")), collapse="."),
                   file=fn,
                   L=round(83960116*mean(tf, na.rm=T)),
                   pop1=seqGetData(genofile, "sample.id")[1],
                   pop2=seqGetData(genofile, "sample.id")[2],
                   projection1=neff[sampleId==seqGetData(genofile, "sample.id")[1]]$ne*2,
                   projection2=neff[sampleId==seqGetData(genofile, "sample.id")[2]]$ne*2)

fn.meta <- paste(dir,
            pairs[job]$data_source, ".",
            pairs[job]$sfs_method, ".",
            pairs[job]$V1, ".",
            pairs[job]$V2, ".",
            pairs[job]$popset,
            ".meta", sep="")

write.table(meta,
            file=fn.meta,
            sep="\t", quote=F, row.names=F, col.names=F)
