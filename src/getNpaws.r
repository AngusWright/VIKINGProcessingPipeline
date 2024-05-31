#
# Select the correct number of paw-prints to create a VIKING-like dataset
#
# Calling syntax: 
# /path/to/Rscript getNpaws.R <wgetscr/catalogue>
#   where: <wgetscr/catalogue> is either a WFAU WGET script or a catalogue of selected images  
#
# VIKING Filter exposure times:
#    Z  = 60s exposure * 1 dither * 4 Jitter * 2 paws per pix = 480s per pix
#    Y  = 25s exposure * 2 dither * 4 Jitter * 2 paws per pix = 400s per pix
#    J  = 25s exposure * 2 dither * 2 Jitter * 4 paws per pix = 400s per pix
#    H  = 10s exposure * 5 dither * 3 Jitter * 2 paws per pix = 300s per pix
#    Ks = 10s exposure * 6 dither * 4 Jitter * 2 paws per pix = 480s per pix
#

suppressWarnings(suppressPackageStartupMessages(require(data.table)))
suppressWarnings(suppressPackageStartupMessages(require(FITSio)))
suppressWarnings(suppressPackageStartupMessages(require(astro)))
suppressWarnings(suppressPackageStartupMessages(require(LAMBDAR)))

#Get command Arguments 
inputs<-commandArgs(TRUE)
#Wget script name
wgetscr<-inputs[1]
#Check if we have a file list or a shell script 
local<- !grepl(".sh",wgetscr)
if (!local) { 
  cat("getNpaws: Note - Input file is shell script, running as NOT local list of files\n")
  wgetscr<-sub('.sh','_Images.sh',wgetscr,fixed=TRUE)
} else {
  cat("getNpaws: Note - Input file is NOT a shell script, running as local list of files\n")
  wgetscr<-sub('.','_withData.',wgetscr,fixed=TRUE)
}
cat(paste("getNpaws: Reading selected images from ",wgetscr,"\n"))
#Convert it to the expected output form from getCatalogueDetails.sh
#Setup Variables
catfin2<-catfin<-NULL
dbin<-1/25 # dbin is 1/25 of a degree 
#Set target exposure times per pix as VIKING total exptime/pix
target.exptime=data.frame(Z=480,Y=400,J=400,H=300,Ks=480)
get0<-function(x,y) { get(paste0(x,y)) }

cat("Determining Filter Observation Stats to match VIKING\n")

#Read relevant catalogues
cat<-fread('catalogue_details.dat',header=T)
n=suppressWarnings(system(paste('grep -c "^#" ',wgetscr),intern=T))
cat2<-fread(wgetscr,skip=n,header=F)
if ( local) { cat2$name<-cat2$V1 }
if (!local) { cat2$name<-cat2[[rev(colnames(cat2))[1]]] }
#Allow 'NA' ESOGRADES; these haven't been graded
if (!is.character(cat$ESOGRADE)) { 
  cat$ESOGRADE<-as.character(cat$ESOGRADE)
}
cat[is.na(ESOGRADE),ESOGRADE:='N']
catcut<-cat[(ESOGRADE!="R")&Seeing > 0.8 & Seeing < 1.2,]
#Check what the detector number stats are like:
for (filt in c("Z","Y","J","H","Ks")) {
  #Initialise Filter counter (counts up to ncount per filter)
  assign(paste0(filt,'count'),0)
  #Check that we have some observations in this filter
  if (length(which(catcut$Filter==filt))==0) { 
    cat(paste("WARNING: there are no",filt,"band paw prints in the catalogue!\n")) 
    assign(paste0("n",filt),0)
    assign(paste0("ndetect",filt),0)
  } else {
    #Bin the Detector positions by RA-DEC 2 arcmin bins
    catcut[Filter==filt,RAdisc:=floor(RAptng/dbin)*(dbin)]
    catcut[Filter==filt,DECdisc:=floor(DECptng/dbin)*(dbin)]
    #Get the number of pointings that measured data in our field
    catcut[Filter==filt,POINTING:=paste0(zapsmall(RAdisc),zapsmall(DECdisc))]
    catcut[Filter==filt,PFACT:=as.numeric(factor(POINTING))]
    tab<-table(catcut[Filter==filt,POINTING])
    #Assign n{Z,Y,J,H,Ks} to be the number of pointings in that filter which observed our field
    assign(paste0("n",filt),length(dimnames(tab)[[1]]))
    #Assign ndetect{Z,Y,J,H,Ks} to be the number of times we've used each pointing for an obs in that filter
    assign(paste0("ndetect",filt),matrix(0,ncol=catcut[Filter==filt,max(PFACT)]))
    #The number of obs per pointing to reach ncount is then approx:
    ncount<-target.exptime[,filt]/mean(catcut[Filter==filt,ExpTime*Ndither*nJitter])/length(get0('n',filt))
    nreq<-ceiling(ncount/get0('n',filt))
    #If any detectors don't have enough observations for this:
    if (any(tab < nreq)) {
      #Which detectors don't have enough?
      for (detector in which(tab < nreq)) {
        #Find the detectors with observations to spare and add one obs to those
        while (any(tab < nreq & tab - sum(get0("ndetect",filt))<nreq)) {
          #Detectors with excess observations
          excess<-which(tab > nreq)
          #Add an obs
          tmp<-get0("ndetect",filt)
          tmp[dimnames(tab)[[1]]][excess]<-tmp[dimnames(tab)[[1]]][excess]-1
          assign(paste0("ndetect",filt),tmp)
        }
      }
    }
  }
}
cat("Looping over image catalogue\n")
#Loop over randomised Image catalogue entries
for (i in sample(length(cat2$name))) {
  string<-cat2$name[i]
  string<-gsub(".fit","",string,fixed=TRUE)
  #If the image is in our field selection catalogue:
  if (any(grepl(string,catcut$File))) {
    #Which filter is it?
    ind<-which(grepl(string,catcut$File))
    #If there haven't been too many of these detectors in this band, nor have there been too many of this band:
    #if(get0('ndetect',catcut$Filter[ind])[catcut$Detector[ind]]<ceiling(ncount/get0('n',catcut$Filter[ind]))&
       #get0(catcut$Filter[ind],'count')<ncount) {
    if(get0('ndetect',catcut$Filter[ind])[catcut$PFACT[ind]]<ceiling(ncount/get0('n',catcut$Filter[ind]))) {
       #Increment the filter counter
       assign(paste0(catcut$Filter[ind],'count'),get0(catcut$Filter[ind],'count')+1)
       #Increment the detector counter counter
       tmp<-get0('ndetect',catcut$Filter[ind])
       tmp[catcut$PFACT[ind]]<-tmp[catcut$PFACT[ind]]+1
       assign(paste0('ndetect',catcut$Filter[ind]),tmp)
       #Output the line
       catfin<-rbind(catfin,cat2[i,])
       catfin2<-rbind(catfin2,catcut[ind,])
    }
  }
}

if (!local) {
  #If !local, output and update the WGET commands
  #Write output table 
  outputscr<-sub(".sh","_selected.sh",wgetscr,fixed=TRUE)
  outputscr2<-sub(".sh","_diagnostic.dat",wgetscr,fixed=TRUE)
  write.table(file=outputscr,catfin,row.names=F,col.names=F,quote=F)
  write.table(file=outputscr2,catfin2,row.names=F,quote=F)
  system(paste("sed -i.bak s/http/\\\'http/ ",outputscr))
  system(paste("sed -i.bak s/\\\ \\\\-O/\\\'\\\ \\\\-O/ ",outputscr))
} else {
  #Write output table 
  outputscr<-sub(".","_selected.",wgetscr,fixed=TRUE)
  outputscr2<-sub(".","_diagnostic.",wgetscr,fixed=TRUE)
  write.table(file=outputscr,catfin,row.names=F,col.names=F,quote=F)
}

#Finished 
