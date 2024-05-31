#
# Script for constructing a low resolution PNG of the fits files 
# within the supplied directories, for eyeballing and QC. 
#
# Syntax: 
# bash makeEyeballMog.sh <Swarp Binary> <R binary> <directory1> <directory2> ...
#

if [ $# -lt 2 ]
then 
  echo 'ERROR: incorrect calling syntax'
  echo '   Correct syntax is:'
  echo '   bash makeEyeballMogOBs.sh <R binary> <directory1> <directory2> ...'
  exit
fi

R=$1
shift

while [ $# -ge 1 ]
do 
  ## create the output filename
  filename=`echo $1 | sed s@.fits@@g`
  outputname=`echo $1 | awk -F '/' '{ print $NF } ' | sed s@.fits@@g`

  # generate the PNG 
  $R --no-save --quiet <<- EOF
  suppressPackageStartupMessages(library(magicaxis));
  suppressPackageStartupMessages(library(data.table));
  suppressPackageStartupMessages(library(LAMBDAR));
  filelist<-system('ls $filename*.fits | grep -v ".weight.fits"',intern=T)
  OBs<-vecsplit(filelist,'/',-1)
  OBs<-vecsplit(OBs,'_',c(1,2))
  cat<-fread('frameDetails.dat')
  png(file='${outputname}_mog.png',height=8*230,width=8*230,res=230); 
  layout<-matrix(0,nrow=16,ncol=nOBs)
  count<-0
  for (i in 1:nOBs) { 
    exist<-which(sapply(grepl,paste0(OBs[i],'_',seq(16)),filelist))
    matrix[exist,i]<-count+exist
    count<-count+length(exist
  }
  for (file in filelist) { 
    im<-read.fits.im('$filename.fits'); 
    astr<-read.astrometry('$filename.fits'); 
    lims=xy.to.ad(c(1,1,astr\$NAXIS[1],astr\$NAXIS[1]),c(1,astr\$NAXIS[2],astr\$NAXIS[2],1),astr); 
    x=seq(lims[1,1],lims[3,1],length=astr\$NAXIS[1]); 
    y=seq(lims[1,2],lims[2,2],length=astr\$NAXIS[2]);
    magimage(x=x,y=y,z=im\$dat[[1]][astr\$NAXIS[1]:1,],magmap=TRUE,stretch='cdf',lo=0.02,hi=0.9,useRaster=TRUE,xlab='RA (deg)',ylab='DEC (deg)');
    filt<-"$1"; 
    filt<-rev(strsplit(filt,"/")[[1]])[2]
  }
  points(cat[Filter==filt,RAchip],cat[Filter==filt,DECchip],pch=3,lwd=2,col=ifelse(cat[Filter==filt,PixMod]>20,'red','blue'))
  rect(218,-2,214,3,density=0,lwd=2,col='red')
  dev.off();
EOF
  
  #go to next directory 
  shift 
  
done
#Finished 
