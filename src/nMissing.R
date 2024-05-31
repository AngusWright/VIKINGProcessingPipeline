#
# returns the number of Paws in path $1 that have 
# no matching reductions in path $2
#

# Command Arguments 
inputs<-commandArgs(TRUE)

# List of paws 
paws<-system(paste0("ls ",inputs[1],'/*.fit'),intern=TRUE,ignore.stderr=TRUE)
# Remove Paths
paws<-sub(inputs[1],'',paws)
paws<-sub('/','',paws)

# List of reductions 
outputs<-system(paste0("ls ",inputs[2],'/*/*.fits'),intern=TRUE,ignore.stderr=TRUE)
# Remove paths 
outputs<-sub(inputs[2],'',outputs)
outputs<-sub('/','',outputs)

#Remove extensions 
paws<-sub('.fit','',paws)
outputs<-sub('.fits','',outputs)

#find missing
Missing<-rep(FALSE,length(paws))
for (i in 1:length(paws)) { 
  Missing[i]<-!any(grepl(paws[i],outputs))
}

#Output number missing
cat(length(which(Missing)))
write.table(file='paws2Update.dat',paws[which(Missing)],quote=FALSE,row.names=FALSE,col.names=FALSE)

