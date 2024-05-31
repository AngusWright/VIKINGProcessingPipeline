library(astroFunctions)
library(data.table)
library(magicaxis)
library(astro)
library(VennDiagram)
cat<-fread("ASTC_SummaryLog.dat")
badWarn<-length(which(cat$NumSWPWarnings > 1))/length(cat$NumSWPWarnings)
badStar<-length(which(cat$NumStars < 10))/length(cat$NumStars)
cat<-fread("results/frameDetails.dat")
summary(cat$PixMod)
length(cat$PixMod)
length(which(cat$PixMod>20))
badMod<-length(which(cat$PixMod > 20))/length(cat$PixMod)
pawlist<-gsub("./Paws/","",system('ls ./Paws/*.fit',intern=TRUE))
sky<-fread("VIKING_PAWS_radec_fixedFileFormat_RADEC.dat")
fullpawlist<-unlist(lapply(strsplit(sky$FILE,"_"),function(x) return=paste0(x[1],"_",x[2],"_st.fit")))
sky<-sky[which(fullpawlist%in%pawlist),]
cat2<-fread("ASTC_SummaryLog.dat")
cat$FileTrunc<-gsub('_r.fits','',cat$File)
cat3<-cat[which(cat$FileTrunc%in%cat2$File),]
cat3<-cat3[order(cat3$FileTrunc),]
cat2<-cat2[order(cat2$File),]
length(which(cat3$FileTrunc!=cat2$File))

png(file='BadPaws.png',height=7*220,width=9*220,res=220)
par(oma=c(4,4,4,4),mar=c(4,4,4,4))
plot.venn(data.frame(CATAID=which(cat3$PixMod > 20)),data.frame(CATAID=(which(cat2$NumStars < 10))),data.frame(CATAID=which(cat2$NumSWPWarnings > 1)),
          names=c("PixMod > 20","NumStars < 10","NumSWPWarns > 1"),main=paste0("Total Number Detectors = ",length(cat2$NumStars))) 
#label('bottomleft',lab=paste0("Total Number Detectors = ",length(cat2$NumStars)))
dev.off()

#Sky Distribution of Processed frames {{{
png(filename="SkyDistribution.png",height=12*220,width=12*220,res=220)
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
  magproj(sky$RA,sky$DEC,
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
  magproj(sex2deg(cat2$RA,cat2$DEC),pch=15,cex=0.2,col=ifelse(cat2$NumSWPWarnings>1|cat2$NumStars < 10|cat3$PixMod > 20,NA,'blue'),type='p',add=T)
  magproj(sex2deg(cat2$RA,cat2$DEC),pch=15,cex=0.2,col=ifelse(cat2$NumSWPWarnings>1|cat2$NumStars < 10|cat3$PixMod > 20,'red',NA),type='p',add=T)
  #}}}
}
dev.off()
#}}}

png(file='var_plots_1.png',height=11*220,width=8*220,res=220)
layout(matrix(1:10,byrow=T,5,2))
par(mar=c(1,1,1,1),oma=c(2,2,1,1))
for (filt in c('Z','Y','J','H','Ks')) {
  pixelhist(cat2$NumStars,cat2$Chi2,cat3$PixMod,pch=20,cex=0.2,ylim=c(quantile(cat2$Chi2,c(0.0,0.995))),xlim=c(0,150),
            density=TRUE,zlim=c(0,20),lo=0.1,hi=0.9,kern.loc='right',subset=cat3$Filter==filt,label.axis=FALSE,
            bw=diff(quantile(cat3$PixMod[cat3$Filter==filt],c(0.1,0.9),na.rm=T))/(80*sqrt(12)),
            xlab=ifelse(filt=='Ks','NumStars',''),ylab='',zlab=ifelse(filt=='Ks','PixMod Factor',''))
  label('topright',lab=paste0(filt,'-band'),cex=2)
}
mtext(side=2,outer=T,text='Chi2')
dev.off()

png(file='var_plots_2.png',height=11*220,width=8*220,res=220)
layout(matrix(1:10,byrow=T,5,2))
par(mar=c(1,1,1,1),oma=c(2,2,1,1))
for (filt in c('Z','Y','J','H','Ks')) {
  pixelhist(cat2$dAXIS1,cat2$dAXIS2,cat2$Chi2,pch=20,cex=0.2,ylim=c(0.0,0.5),xlim=c(0,0.5),
            density=TRUE,zlim=c(0,5),lo=0.1,hi=0.9,kern.loc='right',subset=cat3$Filter==filt,label.axis=FALSE,
            bw=diff(quantile(cat2$Chi2[cat3$Filter==filt],c(0.1,0.9),na.rm=T))/(80*sqrt(12)),
            xlab=ifelse(filt=='Ks','dAXIS1',''),ylab='',zlab=ifelse(filt=='Ks','Chi2',''))
  label('topright',lab=paste0(filt,'-band'),cex=2)
}
mtext(side=2,outer=T,text='dAXIS2')
dev.off()

png(file='var_plots_3.png',height=11*220,width=8*220,res=220)
layout(matrix(1:10,byrow=T,5,2))
par(mar=c(1,1,1,1),oma=c(2,2,1,1))
for (filt in c('Z','Y','J','H','Ks')) {
  pixelhist(cat2$dAXIS1,cat2$dAXIS2,cat2$Chi2,pch=20,cex=0.2,ylim=c(0.0,0.5),xlim=c(0,0.5),
            density=TRUE,zlim=c(0,5),lo=0.1,hi=0.9,kern.loc='right',subset=cat3$Filter==filt,label.axis=FALSE,
            bw=diff(quantile(cat2$Chi2[cat3$Filter==filt],c(0.1,0.9),na.rm=T))/(80*sqrt(12)),
            xlab=ifelse(filt=='Ks','dAXIS1',''),ylab='',zlab=ifelse(filt=='Ks','Chi2',''))
  label('topright',lab=paste0(filt,'-band'),cex=2)
}
mtext(side=2,outer=T,text='dAXIS2')
dev.off()
