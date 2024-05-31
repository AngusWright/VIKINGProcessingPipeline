#
# create.weightmap.r 
#
# Script for creating an output weightmap 
# to mask pixels where there was missing data in the 
# original map.
#
# Script takes a single /path/to/file.fits argument and 
# has no options:
#
# Rscript ./create.weightmap.r /path/to/file.fits

suppressWarnings(suppressPackageStartupMessages(require(FITSio)))
suppressWarnings(suppressPackageStartupMessages(require(astro)))
suppressWarnings(suppressPackageStartupMessages(require(LAMBDAR)))
#Get fits file
inputArgs<-commandArgs(TRUE)
if (any(grepl("--",inputArgs,fixed=T))) { inputArgs = inputArgs[-1*which(grepl("--",inputArgs,fixed=T))] }
inputfile<-inputArgs[[1]]
#Read data map 
if (!file.exists(inputfile)) { stop(paste0(inputfile,' file does not exist')) }
dat<-readFITS(inputfile)
#Determine the NULLVAL
tab<-table(as.numeric(c(dat$imDat[1:51,1:51], #[1,1]
                        dat$imDat[-50:0+dat$axDat$len[1],-50:0+dat$axDat$len[2]], #[N,N]
                        dat$imDat[-50:0+dat$axDat$len[1],1:51], #[N,1]
                        dat$imDat[1:51,-50:0+dat$axDat$len[2]]))) #[1,N]
NULLVAL<-as.numeric(names(tab[which.max(tab)]))
if (tab[which.max(tab)] < 51*51*4/4) {
  NULLVAL<- -Inf
}
#Check for limits of x missing pix 
## Initialise index list 
full.ind<-1:length(dat$imDat[1,])
diff<-NULL
m=2
#Loop up until we have at least 10% of the edge covered in data pixels
while(length(diff)<dat$axDat$len[2]/10) {
  m=m+1
  ## Get indicies of value = 0 pixels in first m rows 
  ind<-which(colAlls(dat$imDat[1:m,]==NULLVAL) | colAlls(dat$imDat[length(dat$imDat[,1])-0:(m-1),]==NULLVAL))
  ## Truncate at first and last gap in index number
  diff<-setdiff(full.ind,ind)
  #If we hit halfway then the whole image is garbage
  if (m>dat$axDat$len[1]/2) { diff=m; break }  
}
if (length(diff) >= 2) { 
  x.limit.lo<-diff[1]
  x.limit.hi<-rev(diff)[1]
} else {
  x.limit.lo<-1
  x.limit.hi<-length(dat$imDat[1,])
}
#Check for limits of y missing pix 
## Initialise index list 
full.ind<-1:length(dat$imDat[,1])
diff<-NULL
m=2
#Loop up until we have at least 10% of the edge covered in data pixels
while(length(diff)<dat$axDat$len[2]/10) {
  m=m+1
  ## Get indicies of value = 0 pixels in first m rows 
  ind<-which(rowAlls(dat$imDat[,1:m]==NULLVAL) | rowAlls(dat$imDat[,length(dat$imDat[1,])-0:(m-1)]==NULLVAL))
  ## Truncate at first and last gap in index number
  diff<-setdiff(full.ind,ind)
  #If we hit halfway then the whole image is garbage
  if (m>dat$axDat$len[2]/2) { diff=m; break }  
}
if (length(diff) >= 2) { 
  y.limit.lo<-diff[1]
  y.limit.hi<-rev(diff)[1]
} else {
  y.limit.lo<-1
  y.limit.hi<-length(dat$imDat[,1])
}
#Generate mask 
wgt<-array(1,dim=dim(dat$imDat))
#Edges    
wgt[1:y.limit.lo,]<-0
wgt[y.limit.hi:length(dat$imDat[,1]),]<-0
wgt[,1:x.limit.lo]<-0
wgt[,x.limit.hi:length(dat$imDat[1,])]<-0
##Mask out other dead pixels 
#wgt[which(dat$imDat==NULLVAL,arr.ind=TRUE)]<-0

#Output updated mask 
writeFITSim(wgt, file=sub('.fits','.weight.fits',inputfile),type="single",axDat=dat$axDat,header=dat$header)

#Finished 
