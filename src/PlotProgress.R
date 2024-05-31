#
#
# Script shows the progress of the processing pipeline
#
#

require(MassFuncFitR)
require(data.table)
require(magicaxis)

#options(device='png')
#Setup {{{
#Read in the list of pawprints that are being reduced {{{
pawlist<-gsub("./Paws/","",system('ls ./Paws/*.fit',intern=TRUE))
#}}}
#Calculate the RADEC of each of these paw detectors {{{
cat<-fread("VIKING_PAWS_radec_fixedFileFormat_RADEC.dat")
fullpawlist<-unlist(lapply(strsplit(cat$FILE,"_"),function(x) return=paste0(x[1],"_",x[2],"_st.fit")))
cat<-cat[which(fullpawlist%in%pawlist),]
miss<-fread("KiDS-450_fields_no_VIKING.txt")
#}}}
#Read in the currently finished paws {{{
comp<-fread("ASTC_SummaryLog.dat")
#}}}
#}}}

#Figures {{{
#Sky Distribution of Processed frames {{{
#dev.new(filename="SkyDistribution.png",height=12*220,width=12*220,res=220)
dev.new(filename="SkyDistribution.png",height=12,width=12)
layout(c(1,2)); par(mar=c(0,0,0,0),oma=c(0,0,0,0))
#Plot the distribution of all paws in grey {{{
for (cen in c(0,180)) { 
  #time<-system.time(radec<-t(pix2world.vec.direct(X=1001,Y=1001,crval1=cat$CRVAL1,crval2=cat$CRVAL2,crpix1=cat$CRPIX1,crpix2=cat$CRPIX2,
  #                 cd11=cat$CD1_1,cd21=cat$CD2_1,cd12=cat$CD1_2,cd22=cat$CD2_2,proj=c('RA---AIT','DEC--AIT'))))
  #RADECs can be approximated quickly with: {{{
  #(cat$CRVAL1-cat$CRPIX2*sqrt(cat$CD2_1^2+cat$CD2_2^2),cat$CRVAL2-cat$CRPIX1*sqrt(cat$CD1_1^2+cat$CD1_2^2)
  #Or can be correctly measured slowly with :
  #radec<-t(pix2world.vec.direct(X=1001,Y=1001,crval1=cat$CRVAL1,crval2=cat$CRVAL2,
  #         crpix1=cat$CRPIX1,crpix2=cat$CRPIX2,cd11=cat$CD1_1,cd21=cat$CD2_1,cd12=cat$CD1_2,cd22=cat$CD2_2,proj=c('RA---AIT','DEC--AIT'))
  ##}}}
  #
  magproj(cat$RA,cat$DEC,
          type='p',pch=15,cex=0.2,col='grey',projection='aitoff', centre=c(cen,0),fliplong=TRUE, labloc=c(90,-45),
          labeltype = 'sex', crunch=TRUE)
  magecliptic(width=10,col=hsv(1/12,alpha=0.3),border=NA)
  magecliptic(width=0,col='orange')
  magMWplane(width=20,col=hsv(v=0,alpha=0.1),border=NA)
  magMWplane(width=0,col='darkgrey')
  magMW(pch=16, cex=2, col='darkgrey')
  magsun(pch=16, cex=2, col='orange2')
  if (cen==0) {
    legend('topright', legend=c('Ecliptic','MW Plane'), col=c(hsv(c(1/12,0), v=c(1,0),alpha=0.5)), pch=c(15,15), lty=c(1,1), bty='n')
  } else {
    legend('bottomleft', legend=c('Sun', 'MW Centre'), col=c('orange2','darkgrey'), pch=16,bty='n')
    legend('bottomright', legend=c('UnProcessed', 'Processed (Passed QC)','Processed (Failed QC)'), col=c('grey','blue','red'), pch=15,bty='n')
  }
  #}}}
  #Overlay the distribution of paws completed {{{
  #magproj(sex2deg(comp$RA,comp$DEC),pch=15,cex=0.2,col=ifelse(comp$NumSWPWarnings>1,'red','blue'),type='p',add=T)
  magproj(miss$V1,miss$V2,type='p',col='purple',pch=0,cex=0.5,add=T)

  #}}}
}
#}}}
##Plot the summary statistics from the NATV Summary File {{{
#dev.new(filename="NATVSummaryStatistics.png",height=10*220,width=10*220,res=220)
#tmpcat<-fread("results/frameDetails.dat")
#magtri.pretty(tmpcat[,cbind(AirMass,ZeroPoint,PixMod,HeaderSkyLevel,HeaderSkyNoise,HeaderSeeing,MeasSeeing,NPSFAccept)],alpha=min(1E4/length(tmpcat[,AirMass]),1),lo=0.001,hi=0.999)
##}}}
##Plot the summary statistics from the ASTC Summary File {{{
#dev.new(filename="ASTCSummaryStatistics.png",height=13*220,width=13*220,res=220)
#tmpcat<-fread("ASTC_SummaryLog.dat")
#magtri.pretty(tmpcat[,cbind(PixScale,NumSWPWarnings,Background,RMS,ExtractorThres,NumDetections,dAXIS1,dAXIS2,Chi2,NumStars)],alpha=min(1E4/length(tmpcat[,PixScale]),1),lo=0.01,hi=0.99)
##}}}
#}}}

if (grepl('png',options('device'),ignore.case=T)) { 
  dev.off()
  #dev.off()
  #dev.off()
}

