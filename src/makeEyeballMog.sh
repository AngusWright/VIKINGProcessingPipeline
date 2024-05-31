#
# Script for constructing a low resolution PNG of the fits files 
# within the supplied directories, for eyeballing and QC. 
#
# Syntax: 
# bash makeEyeballMog.sh <Swarp Binary> <R binary> <directory1> <directory2> ...
#

doSwarp=1

if [ $# -lt 3 ]
then 
  echo 'ERROR: incorrect calling syntax'
  echo '   Correct syntax is:'
  echo '   bash makeEyeballMog.sh <Swarp Binary> <R binary> <directory1> <directory2> ...'
  exit
fi

swarp=$1
shift
R=$1
shift

while [ $# -ge 1 ]
do 
  ##Notify 
  if [ $doSwarp == 1 ]
  then 
    echo "There are `ls $1*_r.fits | wc | awk '{print $1}'` files to swarp in the $1 folder...Running now." 
    ## create the output filename
    inputfiles=`echo $1 | sed s@.fits@@g`
    outputname=`echo $1 | awk -F '/' '{ print $NF }' | sed s@.fits@@g`
    filename=$outputname
    # run swarp
    #$swarp -WEIGHT_TYPE MAP_WEIGHT -IMAGEOUT_NAME $outputname.fits \
    #       -WEIGHTOUT_NAME $outputname.weight.fits -SUBTRACT_BACK N \
    #       -PIXELSCALE_TYPE MANUAL -PIXEL_SCALE 3.39 \
    #       $1*_r.fits  2> SwarpLogfile.dat 
    $swarp -WEIGHT_TYPE MAP_WEIGHT -IMAGEOUT_NAME $outputname.fits \
           -WEIGHTOUT_NAME $outputname.weight.fits -SUBTRACT_BACK N \
           $1*_r.fits  2> SwarpLogfile.dat 
  else
    ## create the output filename
    filename=`echo $1 | sed s@.fits@@g`
    outputname=`echo $1 | awk -F '/' '{ print $NF } ' | sed s@.fits@@g`
  fi

  # generate the PNG 
  $R --no-save --quiet <<- EOF
  suppressPackageStartupMessages(library(magicaxis));
  suppressPackageStartupMessages(library(data.table));
  suppressPackageStartupMessages(library(LAMBDAR));
  im<-read.fits.im('$filename.fits'); 
  cat<-fread('frameDetails.dat')
  astr<-read.astrometry('$filename.fits'); 
  lims=xy.to.ad(c(1,1,astr\$NAXIS[1],astr\$NAXIS[1]),c(1,astr\$NAXIS[2],astr\$NAXIS[2],1),astr); 
  x=seq(lims[1,1],lims[3,1],length=astr\$NAXIS[1]); 
  y=seq(lims[1,2],lims[2,2],length=astr\$NAXIS[2]);
  png(file='${outputname}_mog.png',height=8*230,width=8*230,res=230); 
  magimage(x=x,y=y,z=im\$dat[[1]][astr\$NAXIS[1]:1,],magmap=TRUE,lo=0.02,hi=0.9,useRaster=TRUE,xlab='RA (deg)',ylab='DEC (deg)');
  filt<-"$1"; 
  filt<-rev(strsplit(filt,"/")[[1]])[2]
  points(cat[Filter==filt,RAchip],cat[Filter==filt,DECchip],pch=3,lwd=2,col=ifelse(cat[Filter==filt,PixMod]>20,'red','blue'))
  rect(218,-2,214,3,density=0,lwd=2,col='red')
  dev.off();
EOF
  
  #go to next directory 
  shift 
  
done
#Finished 
