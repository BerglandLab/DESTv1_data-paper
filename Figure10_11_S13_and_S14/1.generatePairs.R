### module load gcc/7.1.0 openmpi/3.1.4 R/3.6.3; R

### libraries
  library(data.table)
  library(SeqArray)
  library(foreach)
  library(bedr)
  library(sp)
  
args = commandArgs(trailingOnly=TRUE)

#Path to the Gworking folder
wd=args[1]
#Path to the metadata
DEST_metadata=args[2]
#Demographic clusters
DEST_clusters=args[3]

### load samps
  setwd(wd)
  samps <- fread(DEST_metadata)

### some basic sample filtering
  samps <- samps[status=="Keep"]
  samps <- samps[propSimNorm<=0.01]

### Get European cluster IDs
  clusters <- fread(DEST_clusters)
  
  samps <- merge(samps, clusters[,c("sampleId", "Continental_clusters"), with=F], by="sampleId")

###################
### E/W cluster ###
###################
  ### make full pairwise table
      pairs <- CJ(samps[Continental_clusters=="1.Europe_W" & set=="DrosEU"]$sampleId,
                  samps[Continental_clusters=="3.Europe_E" & set=="DrosEU"]$sampleId)
      pairs[,popset:="EW"]

  ### attach location information
      setnames(pairs, "V1", "sampleId")
      pairs <- merge(samps, pairs, by="sampleId")[,c("sampleId", "V2", "lat", "long", "popset"), with=F]
      setnames(pairs, c("sampleId", "V2", "lat", "long"), c("V1", "sampleId", "lat.V1", "long.V1"))

      pairs <- merge(samps, pairs, by="sampleId")[,c("V1", "sampleId", "lat.V1", "long.V1", "lat", "long", "popset"), with=F]
      setnames(pairs, c("sampleId", "lat", "long"), c("V2", "lat.V2", "long.V2"))

      pairs[,dist:=spDists(x=as.matrix(pairs[,c("long.V1", "lat.V1"), with=F]),
                            y=as.matrix(pairs[,c("long.V2", "lat.V2"), with=F]), diagonal=T)]

      pairs[,id:=as.character(1:dim(pairs)[1])]

  ### subsample to ~1000 pairs evenly across the distance distribution
      setkey(1234)
      table(round(pairs$dist/20)*20)


      pairs.sample <- pairs[,list(id=rep(sample(id, 200, replace=F))),
                              list(dist.bin=round(dist/20)*20)]
      job_groups <- expand.grid(data_source=c("PoolSNP", "SNAPE"),
                                                     sfs_method=c("counts", "binom"))

      pairs.sample <- pairs.sample[,list(data_source=job_groups$data_source,
                                        sfs_method=job_groups$sfs_method,
                                          dist.bin=dist.bin),
                                    list(id)]

      pairs.sample <- merge(pairs.sample, pairs, by="id")

      table(pairs.sample$popset)

  ### write file
    write.table(pairs.sample, "./pairs_between.txt", row.names=F, quote = F, sep = "\t")

#################
### E/E & W/W ###
#################

  ### make full pairwise table
      pairs_EE <- CJ(samps[Continental_clusters=="3.Europe_E" & set=="DrosEU"]$sampleId,
                  samps[Continental_clusters=="3.Europe_E" & set=="DrosEU"]$sampleId)
      pairs_EE[,popset:="EE"]

      pairs_WW <- CJ(samps[Continental_clusters=="1.Europe_W" & set=="DrosEU"]$sampleId,
                  samps[Continental_clusters=="1.Europe_W" & set=="DrosEU"]$sampleId)
      pairs_WW[,popset:="WW"]
      pairs <- rbind(pairs_EE, pairs_WW)
      pairs <- pairs[V1!=V2]

  ### attach location information
      setnames(pairs, "V1", "sampleId")
      pairs <- merge(samps, pairs, by="sampleId")[,c("sampleId", "V2", "lat", "long", "popset"), with=F]
      setnames(pairs, c("sampleId", "V2", "lat", "long"), c("V1", "sampleId", "lat.V1", "long.V1"))

      pairs <- merge(samps, pairs, by="sampleId")[,c("V1", "sampleId", "lat.V1", "long.V1", "lat", "long", "popset"), with=F]
      setnames(pairs, c("sampleId", "lat", "long"), c("V2", "lat.V2", "long.V2"))

      pairs[,dist:=spDists(x=as.matrix(pairs[,c("long.V1", "lat.V1"), with=F]),
                            y=as.matrix(pairs[,c("long.V2", "lat.V2"), with=F]), diagonal=T)]

      pairs[,id:=as.character(1:dim(pairs)[1])]

      pairs[,id:=sample(id)]

  ### subsample to ~1000 pairs evenly across the distance distribution
      setkey(1234)
      table(round(pairs$dist/20)*20)

      pairs.sample <- pairs[,list(id=rep(sample(id, 200, replace=F))),
                              list(dist.bin=round(dist/20)*20)]
      job_groups <- expand.grid(data_source=c("PoolSNP", "SNAPE"),
                                                     sfs_method=c("counts", "binom"))

      pairs.sample <- pairs.sample[,list(data_source=job_groups$data_source,
                                        sfs_method=job_groups$sfs_method,
                                          dist.bin=dist.bin),
                                    list(id)]

      pairs.sample <- merge(pairs.sample, pairs, by="id")

      table(pairs.sample$popset)
      pairs.sample[,locale1:=paste(tstrsplit(V1, "_")[[1]], tstrsplit(V1, "_")[[2]], sep="_")]
      pairs.sample[,locale2:=paste(tstrsplit(V2, "_")[[1]], tstrsplit(V2, "_")[[2]], sep="_")]

      table(pairs.sample$popset, pairs.sample$locale1==pairs.sample$locale2)

  ### write file
      write.table(pairs.sample, "./pairs_within.txt", row.names=F, quote = F, sep = "\t")


### combine
between <- fread("./pairs_between.txt")
within <- fread("./pairs_within.txt")

all <- rbind(between, within, fill=T)
write.table(all, "./pairs_all.txt", row.names=F, quote = F)
