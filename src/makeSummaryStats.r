#
# makeSummaryStats.r
# Save the Summary Statistics to file and 
# Remove all temporary files generated during 
# doProcessDetector.sh 
#

#Currently running Paws are: {{{
#get the processes running currently; includes program exec names full names
processes<-system('ps t | grep "doProcessDetector"',intern=TRUE)
#List the files that have not been cleaned
files<-suppressWarnings(system('ls v*_st.fits 2> /dev/null',intern=TRUE))
#remove the .fits extension
files<-gsub(".fits","",files)
#}}} 
#Summarise and Remove files not associated with running processes:  {{{
for (i in files) { 
  #Keep the files that are still being processed
  if (!any(grepl(i,processes))) {
    #Initialise {{{
    nat.bg<-nat.rms<-nat.thr<-nat.nd<-nat.ns<-bsb.wrn<-bsb.ra<-bsb.dec<-rep(NA,16)
    bsb.scl<-urt.wrn<-urt.ra<-urt.dec<-urt.scl<-acr.bg<-acr.rms<-acr.thr<-rep(NA,16)
    acr.nd<-acr.ns<-acr.scp.wrn<-acr.scp.dax1<-acr.scp.dax2<-acr.scp.chi2<-rep(NA,16)
    acr.scp.ns<-acr.scp.hsig.dax1<-acr.scp.hsig.dax2<-acr.scp.hsig.chi2<-rep(NA,16)
    acr.scp.hsig.ns<-acr.swp.wrn<-acr.swp.ra<-acr.swp.dec<-acr.swp.scl<-rep(NA,16)
    #}}}
    writeNative<-writeBsub<-writeUrot<-writeAstCor<-FALSE
    for (j in 1:16) { 
      #Create Summary Statistics {{{
      #Native Detector SExtraction {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_NTV_SExLog.dat"))) {
        writeNative<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_NTV_SExLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          log<-log[which((grepl("Objects",log)|grepl("Threshold",log))&!grepl("Line",log))]
          log<-strsplit(log,' ')
          log[[1]]<-log[[1]][which(log[[1]]!="")]
          log[[2]]<-log[[2]][which(log[[2]]!="")]
          nat.bg[j]<-log[[1]][3]
          nat.rms[j]<-log[[1]][9]
          nat.thr[j]<-log[[1]][15]
          nat.nd[j]<-log[[2]][9]
          nat.ns[j]<-log[[2]][16]
        }
      } 
      #}}}
      #BSUB Detector SWarp {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_BSB_SwarpLog.dat"))) {
        writeBsub<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_BSB_SwarpLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          bsb.wrn[j]<-length(which(grepl("WARNING",log)))
          log<-log[which(grepl('Output',log))+2]
          log<-strsplit(log,' ')
          log<-log[[1]][which(log[[1]]!="")]
          bsb.ra[j]<-log[6]
          bsb.dec[j]<-log[7]
          bsb.scl[j]<-log[13]
        }
      } 
      #}}}
      #UROT Detector SWarp {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_URT_SwarpLog.dat"))) {
        writeUrot<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_URT_SwarpLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          urt.wrn[j]<-length(which(grepl("WARNING",log)))
          log<-log[which(grepl('Output',log))+2]
          log<-strsplit(log,' ')
          log<-log[[1]][which(log[[1]]!="")]
          urt.ra[j]<-log[6]
          urt.dec[j]<-log[7]
          urt.scl[j]<-log[13]
        }
      } 
      #}}}
      #ASTC Detector SExtraction {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_ACR_SExLog.dat"))) {
        writeAstCor<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_ACR_SExLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          log<-log[which((grepl("Objects",log)|grepl("Threshold",log))&!grepl("Line",log))]
          log<-strsplit(log,' ')
          log[[1]]<-log[[1]][which(log[[1]]!="")]
          log[[2]]<-log[[2]][which(log[[2]]!="")]
          acr.bg[j]<-log[[1]][3]
          acr.rms[j]<-log[[1]][5]
          acr.thr[j]<-log[[1]][8]
          acr.nd[j]<-log[[2]][4]
          acr.ns[j]<-log[[2]][7]
        }
      } 
      #}}}
      #ASTC Detector SCamp {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_ACR_ScampLog.dat"))) {
        writeAstCor<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_ACR_ScampLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          acr.scp.wrn[j]<-length(which(grepl("WARNING",log)))
          log<-log[which(grepl('Astrometric stats',log)&grepl('external',log))+4]
          log<-strsplit(log,' ')
          log<-log[[1]][log[[1]]!=""]
          log<-gsub("\"","",log)
          acr.scp.dax1[j]<-log[3]
          acr.scp.dax2[j]<-log[4]
          acr.scp.chi2[j]<-log[5]
          acr.scp.ns[j]<-log[6]
          acr.scp.hsig.dax1[j]<-log[7]
          acr.scp.hsig.dax2[j]<-log[8]
          acr.scp.hsig.chi2[j]<-log[9]
          acr.scp.hsig.ns[j]<-log[10]
        }
      } 
      #}}}
      #ASTC Detector SWarp {{{
      if (file.exists(paste0("./Logs/",i,"_",j,"_ACR_SwarpLog.dat"))) {
        writeAstCor<-TRUE
        log<-system(paste0("cat ./Logs/",i,"_",j,"_ACR_SwarpLog.dat"),intern=TRUE)
        if (!any(grepl("Error",log))) { 
          acr.swp.wrn[j]<-length(which(grepl("WARNING",log)))
          log<-log[which(grepl('Output',log))+2]
          log<-strsplit(log,' ')
          log<-log[[1]][which(log[[1]]!="")]
          acr.swp.ra[j]<-log[2]
          acr.swp.dec[j]<-log[3]
          acr.swp.scl[j]<-log[6]
        }
      } 
      #}}}
      #}}}
    }
    # Write Summary Statistics {{{
    if (writeNative) {
      write.table(data.frame(paste0(i,"_",1:16),nat.bg,nat.rms,nat.thr,nat.nd,nat.ns),
                  quote=FALSE,row.names=FALSE,col.names=FALSE,file='NATV_SummaryLog.dat',append=TRUE)
    }
    if (writeBsub) {
      write.table(data.frame(paste0(i,"_",1:16),bsb.ra,bsb.dec,bsb.scl,bsb.wrn),
                  quote=FALSE,row.names=FALSE,col.names=FALSE,file='BSUB_SummaryLog.dat',append=TRUE)
    }
    if (writeUrot) {
      write.table(data.frame(paste0(i,"_",1:16),urt.ra,urt.dec,urt.scl,urt.wrn),
                  quote=FALSE,row.names=FALSE,col.names=FALSE,file='UROT_SummaryLog.dat',append=TRUE)
    }
    if (writeAstCor) {
      write.table(data.frame(paste0(i,"_",1:16),acr.swp.ra,acr.swp.dec,acr.swp.scl,acr.swp.wrn,acr.bg,
                           acr.rms,acr.thr,acr.nd,acr.ns,acr.scp.dax1,acr.scp.dax2,acr.scp.chi2,
                           acr.scp.ns,acr.scp.hsig.dax1,acr.scp.hsig.dax2,acr.scp.hsig.chi2,acr.scp.hsig.ns),
                  quote=FALSE,row.names=FALSE,col.names=FALSE,file='ASTC_SummaryLog.dat',append=TRUE)
    }
    #}}}
    #Remove Temporary Files {{{
    system(paste0("/bin/rm -f chi_*",i,"*.fits"))
    system(paste0("/bin/rm -f proto_",i,"*.fits"))
    system(paste0("/bin/rm -f PSFmatrix_*",i,"*.dat"))
    system(paste0("/bin/rm -f resi_*",i,"*.fits"))
    system(paste0("/bin/rm -f samp_*",i,"*.fits"))
    system(paste0("/bin/rm -f *",i,"*.psf"))
    system(paste0("/bin/rm -f snap_*",i,"*.fits"))
    system(paste0("/bin/rm -f *",i,"*.xml"))
    system(paste0("/bin/mv -f ",i,"_*_processLog.dat ./Logs/ProcessLogs/"))
    #}}}
    #Remove uncompressed Paw {{{
    system(paste0("/bin/rm -f ",i,".fits"))
    if (file.exists("./src/removePaws.sh")) { 
      system(paste0("/bin/rm -f ./Paws/",i,".fit"))
    }
    #}}}
  }
}
#}}}

#Finished
