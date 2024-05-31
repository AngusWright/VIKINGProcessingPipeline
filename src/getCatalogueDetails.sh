#
# Get the relevant details for pawprint selection
# from each of the WFAU PawPrint Catalogues. The script
# uses the output logfile from selectPaws.sh to determine
# the file list here, so this should be run immediately
# after selectPaws, or in the same directory as it was run
# prior to the catalogues being moved elsewhere...
#
# Calling Syntax:
#    bash getCatalogueDetails.sh [--update] </path/to/scripts/> </path/to/R>
#

# Stop on error {{{
set -e
#}}}

#Check if we want to update #{{{
update=$1
if [ "$update" == "--update" ]
then
  updt=1
  shift
else 
  updt=0
fi
#}}}

#Progress Bar Function {{{
source $1/progressbar.sh
shift
#}}}

#Defile the R installation #{{{
R=$1
if [ $# -eq 0 ]
then
  R=`which R`
fi
#}}}

#Remove 0 number entries from the catalogue #{{{
grep -v "N=0" selectPaws_logfile.dat > selectPaws_logfile_cut.dat
#}}}

#Variable definition {{{
let start=`date +%s`/60
count=1
total=`wc selectPaws_logfile_cut.dat | awk '{print $1}'`
#}}}

# Notify {{{
echo -n "Looping over $total catalogue files"
#}}}

#Initialise the catalogue_details file #{{{
if [ $updt == 1 ] 
then
  if [ -e catalogue_details.dat ]
  then
    count=`wc catalogue_details.dat | awk '{print $1}'`
    echo " (starting at line $count):"
    tail -n +$count selectPaws_logfile_cut.dat > tmp
    mv tmp selectPaws_logfile_cut.dat
  else
    echo 'File,RAptng,DECptng,Filter,Seeing,ESOGRADE,ExpTime,Ndither,nJitter,Detector' > catalogue_details.dat
    echo ":"
  fi
else
  echo 'File,RAptng,DECptng,Filter,Seeing,ESOGRADE,ExpTime,Ndither,nJitter,Detector' > catalogue_details.dat
fi
#}}}

#Loop through the catalogue list {{{
while read line
do
  #Get number of the detector {{{
  n=`echo $line | awk -F ',' '{print $1}' | awk -F '#' '{print $2}'`
  #}}}
  #Get the catalogue name {{{
  cata=`echo $line | awk -F ',' '{print $1}' | awk -F '#' '{print $1}'`
  #}}}
  #output the catalogue details to file {{{
  echo ` $R --slave << EOF
suppressPackageStartupMessages(require(astro)); 
cat(paste(read.fitskey('RA','$cata'), 
read.fitskey('DEC','$cata'), 
read.fitskey('ESO INS FILT1 NAME','$cata'), 
read.fitskey('ESO TEL GUID FWHM','$cata'), 
read.fitskey('ESOGRADE','$cata'), 
read.fitskey('ESO DET DIT','$cata'), 
read.fitskey('ESO DET NDIT','$cata'), 
read.fitskey('NJITTER','$cata'), sep=','))
EOF
` | awk -v CAT=$cata -v NUM=$n '{print CAT","$0","NUM}' >> catalogue_details.dat
  #}}}
  #Update progressbar {{{
  progressBar $count $total $start
  let count=$count+1
  #}}}
done < selectPaws_logfile_cut.dat
#}}}

#Finished
