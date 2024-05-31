#
# This script is a sub-script within the doPreprocessing.sh script.
# As such, it will typically not need to be called directly.
# Nonetheless, correct calling syntax is:
# ./doReduceDetector.r [[--update]] [[--args]] <input_file> <header_unit> <output_file> <desired_seeing>
#
#    Here:
#    [--update] is an optional command that causes processing only if the paw-print has not already been processed 
#    [[--args]] are optional command args controlled by R, but MUST have leading '--'
#    <input_file> is the filename of the paw-print you want to preprocess
#    <header_unit> is the HDU extension of the detector you want to reduce.
#         NB: VISTA Pawprints have a single leading empty HDU. So, detector 1 is HDU 2, and so on.
#    <output_file> is the filename to which you want to output the processed detector
#    <desired seeing> is optional and need not be provided.
#    If no <desired seeing> is provided, 0'' seeing is used by default.
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

# Check for the presence of the required packages
if (!all(c("LAMBDAR","FITSio","astro") %in% rownames(installed.packages()))) {
  pacs<-c("LAMBDAR","FITSio","astro")
  pacs<-pacs[!c("LAMBDAR","FITSio","astro")%in%rownames(installed.packages())]
  cat(paste("ERROR: Required package",pacs,"is not available!\n",collapse='\n'))
  q(save='no',status=1)
}
suppressWarnings(suppressPackageStartupMessages(require(FITSio)))
suppressWarnings(suppressPackageStartupMessages(require(astro)))
suppressWarnings(suppressPackageStartupMessages(require(LAMBDAR)))

# input arguments
inputargs = commandArgs(TRUE)
Diagnostic=FALSE
update=FALSE
#Check for diagnostic call
if (any(grepl("--diagnostic",inputargs,fixed=T))) { Diagnostic<-TRUE }
if (any(grepl("--update",inputargs,fixed=T))) { update<-TRUE }
#Remove other command arguments handled by R
if (any(grepl("--",inputargs,fixed=T))) { inputargs = inputargs[-1*which(grepl("--",inputargs,fixed=T))] }
# Check number of remaining input arguments
# If 3 arguments - must be no seeing measurement
if(length(inputargs) == 3){
    inp = inputargs[1]
    header = inputargs[2]
    out = inputargs[3]
    inpsee= 0.0            # default seeing to 0.0''
} else if (length(inputargs) == 4){
# If 4 arguments - must be a seeing measurement
    inp = inputargs[1]
    header = inputargs[2]
    out = inputargs[3]
    inpsee = as.numeric(inputargs[4])
} else {
# If < 3 or > 4 arguments - Print Error & break
stop("Incorrect number of Command Arguments\n",
    " Correct syntax:\n",
    "      ./doReduceDetector.r [[--args]] <input_file> <header_unit> <output_file> <desired_seeing>\n",
    " [[--args]] are command args parse to R, but MUST have leading '--'\n",
    " <desired seeing> is optional and need not be provided.\n",
    " If no <desired seeing> is provided, 0.0'' seeing is used by default (i.e. no convolution).\n")
}

if (update) { 
  fulllist<-system('ls ./results/native/*/*.fits',intern=TRUE)
} else {
  fulllist<-""
}
if (!((update)&any(grepl(out,fulllist)))) { 
  # Read the FITS file using readFITS (because of bug in astro write.fits: 10.10.16)
  dat = readFITS(file=inp,hdu=as.numeric(header)-1)
  
  # Read VISTA Observation Parameters defined in the first FITS header
  parlist<-read.fitskey(c("ESO INS FILT1 NAME","RA","DEC","EXPTIME","ESO TEL AIRM START","ESO TEL AIRM END"),file=inp,hdu=1)
  #Filter Name
  filter = parlist[1]
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
  if (is.na(satur)) { 
    satlab='NOSATURLABEL'
    satur=5e9
  } else { 
    satlab='SATURATE'
  }
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
  
  # Modify the pixel data
  dat$imDat = dat$imDat * pixmod
  # Modify the gain (e-/ADU)
  gain=gain / pixmod
  # Modify the saturation (ADU)
  satur=satur * pixmod
  # Modify the Sky Level
  skylev=skylev * pixmod
  # Modify the Sky RMS
  skynois=skynois * pixmod
  
  # Output the new image to our output file
  writeFITSim(dat$imDat, file=out, type="single", axDat=dat$axDat, header=dat$header)
  # Update the output files FITS keywords as required
  write.fitskey("RA", value=ra, file=out,hdu=1) # Should change nothing
  write.fitskey("DEC", value=dec, file=out,hdu=1) # Should change nothing
  write.fitskey("MAGZPT", value=30.0, file=out,hdu=1) # The new Zero Point Magnitude
  write.fitskey("GAINCOR", value=gain, file=out,hdu=1) # The new gain value
  write.fitskey("GAIN", value=gain, file=out,hdu=1) #The new gain value again, with a different keyword
  write.fitskey(satlab, value=satur, file=out,hdu=1) #The new saturation value, or a dummy if it wasn't read.
  
  # SourceExtractor and PSFex Binary locations (should have been setup in the Definitions.sh file)
  sex = "./bin/sex"
  psfex = "./bin/psfex"
  
  # output file name
  sexout = paste0("./catalogues/",filter,"/",sub(".fits","_stars_sexcat.fits",out))
  system(paste0('mkdir -p ./catalogues/',filter,'/'))
  
  # Set VISTA pixelsize
  pixsize=mean(sqrt(astr$CD[1,1]^2+astr$CD[1,2]^2),sqrt(astr$CD[2,2]^2+astr$CD[2,1]^2))*3600
  
  # Generate the required convolution filter kernel
  if (inpsee > 0) { 
    source("./src/makePSF.r")
    psffile=paste0('PSFmatrix_',header,'.dat')
    makePSF(targetFWHM=inpsee,pixelgrid=22,res=pixsize,dofile=T,file=psffile)
  }
  
  # Run SourceExtractor on Reduced Native Frame
  if (inpsee > 0) { 
    sexcmdline = system(paste(sex, out, "-c psf.sex.config -CATALOG_NAME", sexout, "-FILTER Y -FILTER_NAME",psffile,
                 "-SATUR_LEVEL",satur,"-SATUR_KEY",satlab,"-MAG_ZEROPOINT", zeropnt, "-GAIN", gain, "-PIXEL_SCALE",pixsize, 
                 ifelse(Diagnostic,"","2>&1")), intern=TRUE)
    write.table(file=paste0("./Logs/",gsub('_r.fits','',out),'_NTV_SExLog.dat'),sexcmdline,row.names=F,col.names=F)
  } else {
    sexcmdline = system(paste(sex, out, "-c psf.sex.config -CATALOG_NAME", sexout, "-FILTER N -SATUR_LEVEL",satur,
                "-SATUR_KEY",satlab,"-MAG_ZEROPOINT", zeropnt, "-GAIN", gain, "-PIXEL_SCALE", pixsize,
                ifelse(Diagnostic,"","2>&1")), intern=TRUE)
    write.table(file=paste0("./Logs/",gsub('_r.fits','',out),'_NTV_SExLog.dat'),sexcmdline,row.names=F,col.names=F,quote=F)
  }
  
  # Run PSFEx on Reduced Native Frame
  psfexcmdline = system(paste(psfex, sexout, "-c psfex.config ",ifelse(Diagnostic,"","2>&1")), intern=TRUE)
  write.table(file='./Logs/PSFExReductionLog.dat',psfexcmdline,row.names=F,col.names=F)
  
  # Read the PSFEx Results
  linenum = grep('Saving CHECK-image #1', psfexcmdline) - 1
  # All the important PSFEx Outputs
  results = strsplit(psfexcmdline[linenum], " +")
  # Number of PSFs accepted in the modelling
  psfaccept=strsplit(results[[1]][2], "/", fixed=T)[[1]][1]
  # Number of PSFs available in the modelling
  psftotal=strsplit(results[[1]][2], "/", fixed=T)[[1]][2]
  # Chi2 of the PSF model
  psfchi2=results[[1]][4]
  # FWHM of the PSF model (in pix)
  psfFWHMpix=results[[1]][5]
  # FWHM of the PSF model (in asec)
  psfFWHM=as.numeric(psfFWHMpix)*pixsize
  
  # Write the measured PSF Seeing to the output file
  write.fitskey("PSFSEE",psfFWHM,file=out)
  
  # Convolution variable definition
  convolutionfactor = 2*sqrt(2*log(2))
  seeing=psfFWHM
  postconvseeing = inpsee # set in command arguments (arcseconds).
  
  # Now determine if file needs to be convolved or not (i.e. if the seeing in the file is less than the value we want (=postconvseeing).
  # Place new files in output folder and log what is done.
  
  # convolved output file name
  if (inpsee > 0) { 
    cout=paste("c_",out,sep="")
    cout=sub("native","convolved",cout)
    sexout = sub("sexcat","sexcat_conv",sexout)
  } else { 
    cout=out
  }
  
  # Start of convolution section
  if(seeing < postconvseeing){
    # Seeing is less than the desired seeing, so colvolve
    # Convolution kernel FWHM
    convolvedseeing = convolutionfactor * sqrt((postconvseeing/convolutionfactor)^2 - (seeing/convolutionfactor)^2)
    # Convolution kernel sigma
    sigma = (convolvedseeing/pixsize)/convolutionfactor
    # Check that the file doesn't already exist
    if (file.exists(cout)) { system(paste('rm',cout)) }
    # Run FGauss for the convolution
    stat=try(system(paste("./bin/fgauss '", out,"'"," '",cout,"' ", sigma, "",sep="")))
  }else if ( inpsee > 0 ) {
    # Seeing is equal to or greater than desired seeing, so no convolution needed.
    if (file.exists(paste0(cout))) { system(paste('rm',cout)) }
    # ImCopy instead of convolve
    system(paste("./bin/imcopy ",out," ",cout,sep=""))
    sigma=0.0
  } else {
    sigma=NA
  }
  
  # run source extractor on convolved frame
  if (inpsee > 0) { 
    sexcmdline = system(paste(sex, cout, "-c psf.sex.config -CATALOG_NAME", sexout, "-FILTER Y -FILTER_NAME ",
                 psffile," -SATUR_LEVEL",satur,"-SATUR_KEY",satlab,"-MAG_ZEROPOINT", zeropnt, "-GAIN", gain, "-PIXEL_SCALE", 
                 pixsize, "2>&1"), intern=TRUE)
    write.table(file='./Logs/SExtractorConvReductionLog.dat',sexcmdline,row.names=F,col.names=F)
  
  # run PSFEx on convolved frame
    psfexcmdline = system(paste(psfex, sexout, "-c psfex.config 2>&1"), intern=TRUE)
    write.table(file='./Logs/PSFExConvReductionLog.dat',psfexcmdline,row.names=F,col.names=F)
  }
  
  # results
  linenum = grep('Saving CHECK-image #1', psfexcmdline) - 1
  results = strsplit(psfexcmdline[linenum], " +")
  psfFWHMpix=results[[1]][5]
  psfFWHM=as.numeric(psfFWHMpix)*pixsize
  
  # Write post-convolution seeing to convolved file
  write.fitskey("PSFSEE",psfFWHM,file=cout)
  origsee=as.numeric(hdrseeing)*pixsize
  rachip= astr$CRVAL[1]
  decchip= astr$CRVAL[2]
  raoff= astr$CRPIX[1]
  decoff= astr$CRPIX[2]
  rachip=rachip-raoff*astr$CD[1,1]-raoff*astr$CD[1,2] # RA of the chip corner
  decchip=decchip-decoff*astr$CD[2,2]-decoff*astr$CD[2,1] # DEC of the chip corner
  # End of convolution section
  
  # output useful info
  write.table(file='frameDetails.dat',quote=FALSE,row.names=FALSE,append=TRUE,col.names=FALSE,
    list(out,rachip,decchip,filter,exptime,airmass,extinct,naxis1,naxis2,zeropnt,pixmod,skylev,skynois,origsee,seeing,psfaccept,psftotal,psfFWHM,sigma,pixsize))
  cat(paste(out,rachip,decchip,filter,exptime,airmass,extinct,naxis1,naxis2,zeropnt,pixmod,skylev,skynois,origsee,seeing,psfaccept,psftotal,psfFWHM,sigma,pixsize,"\n"))
}

# Finished

