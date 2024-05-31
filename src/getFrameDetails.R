#
# This script is a side-script for the doPreprocessing.sh script.
# The correct calling syntax is:
# ./getFrameDetails.r [[--args]] <native_directory>
#
#    Here:
#    [[--args]] are optional command args controlled by R, but MUST have leading '--'
#    <input_file> is the filename of the paw-print you want to preprocess
#
# Some parameters are hard coded in this script:
#   default desired seeing (of the convolved images) is 0" (no convolve)
#   post-processed image zero point is hard coded to 30
#   VISTA pixel scale is hard coded to be 0.339"
#   AB-VEGA conversion factors are:
#     - Z  = 0.521
#     - Y  = 0.618
#     - J  = 0.937
#     - H  = 1.384
#     - Ks = 1.839
#

suppressWarnings(suppressPackageStartupMessages(require(data.table)))
suppressWarnings(suppressPackageStartupMessages(require(FITSio)))
suppressWarnings(suppressPackageStartupMessages(require(astro)))
suppressWarnings(suppressPackageStartupMessages(require(LAMBDAR)))

# Check for the presence of the required packages
if (!all(c("FITSio","astro") %in% rownames(installed.packages()))) {
  cat("ERROR: Required packages are not available!\n")
  q(save='no',status=2)
}
require(FITSio)
require(astro)

# input arguments
inputargs = commandArgs(TRUE)
#Check for diagnostic call
Diagnostic=FALSE
if (any(grepl("--diagnostic",inputargs,fixed=T))) { Diagnostic<-TRUE }
#Check for PSF FWHM call
getPSFFWHM=FALSE
if (any(grepl("--getfwhm",inputargs,fixed=T))) { getPSFFWHM<-TRUE }
#Remove other command arguments handled by R
if (any(grepl("--",inputargs,fixed=T))) { inputargs = inputargs[-1*which(grepl("--",inputargs,fixed=T))] }
# Check number of remaining input arguments
# If 3 arguments - must be no seeing measurement
if(length(inputargs) == 1){
    folder = inputargs[1]
} else {
# If != 1
stop("Incorrect number of Command Arguments\n",
    " Correct syntax:\n",
    "      ./getFrameDetaile.r [[--args]] <native_directory>\n",
    " [[--args]] are command args parse to R, but MUST have leading '--'\n",
    " <native_directory> is the native directory created during processing.\n")
}

list<-system(paste0('ls ',folder,'/*/*.fits | grep -v ".weight."'),intern=TRUE)
header=1

cat("File RAchip DECchip Filter ExpTime AirMass Extinct Naxis1 Naxis2 ZeroPoint PixMod HeaderSkyLevel HeaderSkyNoise HeaderSeeing MeasSeeing NPSFAccept NPSFTotal PostConvSeeing ConvSigma PixSize") 

for (inp in list) {
  # Read VISTA Observation Parameters defined in the FITS header

  if (getPSFFWHM) { 

  } else { 
    # Number of PSFs accepted in the modelling
    psfaccept=NA
    # Number of PSFs available in the modelling
    psftotal=NA
    # Chi2 of the PSF model
    psfchi2=NA
    # FWHM of the PSF model (in pix)
    psfFWHMpix=NA
    # FWHM of the PSF model (in asec)
    psfFWHM=NA
  }
  
  # Convolution variable definition
  convolutionfactor = 2*sqrt(2*log(2))
  seeing=psfFWHM
  
  sigma=0.0
  

  # Read VISTA Observation Parameters defined in the first FITS header
  parlist<-read.fitskey(c("ESO INS FILT1 NAME","RA","DEC","EXPTIME","ESO TEL AIRM START","ESO TEL AIRM END"),file=inp,hdu=1)
  #Filter Name
  filter = rev(unlist(strsplit(inp,'/')))[2]
  #RA
  ra = as.numeric(parlist[2])
  #Declination
  dec = as.numeric(parlist[3])
  #Exposure time per Dither
  exptime = as.numeric(parlist[4])
  #Average Airmass
  airmass = (as.numeric(parlist[5]) + as.numeric(parlist[6]))/2
  # Read Detector specific parameters defined in the detector FITS header
  parlist<-read.fitskey(c("MAGZPT","SATURATE","EXTINCT","NAXIS1","NAXIS2","GAINCOR","SKYLEVEL","SKYNOISE","SEEING"),file=inp,hdu=as.numeric(header))
  #Zero Point Magnitude
  zeropnt = as.numeric(parlist[1])
  #Saturation level 
  satur = as.numeric(parlist[2])
  #Extinction
  extinct = as.numeric(parlist[3])
  #Image dimension in X
  naxis1 = as.numeric(parlist[4])
  #Image dimension in Y
  naxis2 = as.numeric(parlist[5])
  # Gain
  gain = as.numeric(parlist[6])
  # Read in CASU/WFAU SkyLevel 
  skylev = as.numeric(parlist[7])
  # Read in CASU/WFAU sky RMS 
  skynois = as.numeric(parlist[8])
  # Read in CASU/WFAU Seeing 
  hdrseeing = as.numeric(parlist[9])
  # Read the astrometry information
  astr = read.astrometry(inp,hdu=as.numeric(header))
  
  # Determine which Filter we're analysing
  if(! filter %in% c("Z","Y","J","H","Ks")) { 
    warning(paste0("Filter not one of YZJHKs; assuming no AB-Vega correction!!\nFilter is: ",filter))
  }
  # Set the appropriate AB-Vega conversion factor
  abv=0
  if(filter=="Z") {abv=0.521}
  if(filter=="Y") {abv=0.618}
  if(filter=="J") {abv=0.937}
  if(filter=="H") {abv=1.384}
  if(filter=="Ks") {abv=1.839}
  
  # Calculate the correct AB-magnitude ZP
  zeropnt.new = zeropnt - (2.5*log10(1/exptime)) - (extinct*(airmass-1)) + abv
  
  # Calculate the multiplicative Pixel Modifier factor
  # required to renormalise the image to MagZP=30 (~1ADU per Photon)
  pixmod = 10^(-0.4*(zeropnt.new-30))
  
  # Modify the gain (e-/ADU)
  gain=gain / pixmod
  # Modify the saturation (ADU)
  satur=satur * pixmod
  # Modify the Sky Level
  skylev=skylev * pixmod
  # Modify the Sky RMS
  skynois=skynois * pixmod
  
  # Set VISTA pixelsize
  pixsize=mean(abs(c(astr$CD[1,1]/cos(atan(astr$CD[2,1]/astr$CD[2,2]))*3600,astr$CD[2,2]/(cos(atan(astr$CD[2,1]/astr$CD[2,2])))*3600)))
  
  origsee=as.numeric(hdrseeing)*pixsize
  rachip= astr$CRVAL[1]
  decchip= astr$CRVAL[2]
  raoff= astr$CRPIX[1]
  decoff= astr$CRPIX[2]
  rachip=rachip-raoff*astr$CD[1,1]-raoff*astr$CD[1,2] # RA of the chip corner
  decchip=decchip-decoff*astr$CD[2,2]-decoff*astr$CD[2,1] # DEC of the chip corner
  # End of convolution section
  
  # output useful info
  inp<-rev(unlist(strsplit(inp,'/')))[1]
  write.table(file='frameDetails.dat',quote=FALSE,row.names=FALSE,append=TRUE,col.names=FALSE,
    list(inp,rachip,decchip,filter,exptime,airmass,extinct,naxis1,naxis2,zeropnt,pixmod,skylev,skynois,origsee,seeing,psfaccept,psftotal,psfFWHM,sigma,pixsize))
  cat(paste(inp,rachip,decchip,filter,exptime,airmass,extinct,naxis1,naxis2,zeropnt,pixmod,skylev,skynois,origsee,seeing,psfaccept,psftotal,psfFWHM,sigma,pixsize,"\n"))
}

# Finished

