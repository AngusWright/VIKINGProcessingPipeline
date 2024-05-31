#
# Script returns the entires of <catalogue> that are missing from <Folder> 
#

suppressWarnings(suppressPackageStartupMessages(require(data.table)))
suppressWarnings(suppressPackageStartupMessages(require(FITSio)))
suppressWarnings(suppressPackageStartupMessages(require(astro)))
suppressWarnings(suppressPackageStartupMessages(require(LAMBDAR)))

inputargs<-commandArgs(TRUE)
if (any(grepl("--diagnostic",inputargs,fixed=T))) { Diagnostic<-TRUE }
#Remove other command arguments handled by R
if (any(grepl("--",inputargs,fixed=T))) { inputargs = inputargs[-1*which(grepl("--",inputargs,fixed=T))] }
# Check number of remaining input arguments
if(length(inputargs) != 2){
# If no input arguments 
stop("Incorrect number of Command Arguments\n",
    " Correct syntax:\n",
    "      ./missingDetectors.R [[--args]] <frameDetails.dat file> <detector folder> \n",
    " [[--args]] are command args parse to R, but MUST have leading '--'\n",
    " <frameDetails.dat file> is the frameDetails.dat file\n",
    " <detector folder> is the folder containing the detectors you want to cross-check against.\ne.g. native_astcorr/")
} else {
  catalogue<-inputargs[1]
  folder<-inputargs[2]
}

if (file.exists(catalogue)) { 
  cat<-fread(catalogue)
} else {
  str<-paste('catalogue',catalogue,'does not exist. Current Directory is',getwd(),'.')
  stop(str)
}

if (grepl('astcorr',folder)) { 
  substr<-'_st_astcorr'
} else if (grepl('bsub',folder)) {
  substr<-'_st_bsub'
} else if (grepl('urot',folder)) {
  substr<-'_st_urot'
} else {
  substr<-'_st'
}

checkfiles<-paste0(folder,'/',cat$Filter,'/',sub('_st',substr,cat$File))
logic<-file.exists(checkfiles)
if (length(which(logic)) > 0) { 
  cat<-cat[-which(logic),]
}
write.table(cat,file='missingDetectors.dat',quote=F,row.names=F)


