#
#	doPreprocessing.sh
# format of call: ./doPreprocessing.sh Path/To/Scripts/ Path/To/PAWS/
#

######################
##  Hello Scientist ##
##     Hopefully    ##
##   You shouldn't  ##
##     need to be   ##
##   editing this.. ##
######################

#Welcome {{{
echo -e "\033[0;34m###############################################\033[0m"
echo -e "\033[0;34m##\033[0;31m VISTA VIKING PreProcessing Pipeline v1.0  \033[0;34m##\033[0m"
echo -e "\033[0;34m##\033[0;31m      Written by A.H.Wright (11-10-16)     \033[0;34m##\033[0m"
echo -e "\033[0;34m###############################################\033[0m"
#}}}

# Set stop on error {{{
abort()
{
echo -e "\033[0;34m###############################################\033[0m" >&2
echo -e "\033[0;34m##\033[0;31m                   !FAILED!                \033[0;34m##\033[0m" >&2
echo -e "\033[0;34m##\033[0;31m   An error occured during the step above  \033[0;34m##\033[0m" >&2
echo -e "\033[0;34m###############################################\033[0m" >&2
echo >&2
echo >&2
echo -e "\033[0;34m## For Debugging Run: \033[0m" >&2
echo -e "\033[0m      bash /path/to/doPreprocessing.sh \033[0;31m--DEBUG\033[0m /path/to/scripts/ /path/to/PAWS/ 2> my_big_logfile.dat \033[0m" >&2
echo -e "\033[0;34m## BE SURE TO DUMP STDERR TO FILE! DEBUG will output _EVERY_ command executed prior to the error!\033[0m" >&2
echo -e "\033[0;34m## The last few lines of this file will tell you which command failed. \033[0m" >&2
echo >&2
exit 1
}
trap 'abort' 0
set -e
#}}}

#Check for debug {{{
if [ "$1" == "--DEBUG" ]
then
echo -e "\033[0;34m###############################################\033[0m" >&2
echo -e "\033[0;34m##\033[0;31m                !DEBUG MODE!               \033[0;34m##\033[0m" >&2
echo -e "\033[0;34m###############################################\033[0m" >&2
set -x
trap 'set +x' 0
shift
fi
#}}}

#Check for correct calling syntax {{{
if [ $# != 2 ]
then
  echo -e "ERROR - Incorrect calling syntax:\n./doPreprocessing.sh Path/To/Scripts Path/To/PAWS/"
  exit
fi
#}}}

#Remove old .process_status_running file {{{
rm -fr .process_status_running 
#}}}

#Variable Definition {{{
echo -e "\033[0;34mInitialising\033[0m"
scripts=$1
paws=$2
let start=`date +%s`/60
# Binary Path definitions {{{
source $scripts/PATHS.sh || echo -e "\033[0;31mERROR: Failed to source $scripts/PATHS.sh.\nThere are likely broken paths being defined using 'which'!\033[0m"
#}}}
#Setup Required Files {{{
mkdir -p bin src Logs Logs/ProcessLogs/
echo -e "\033[0;34mGetting binary paths from PATHS.sh File\033[0m"
#Setup Preprocessing Binaries {{{
cd bin
ln -sf $sex .     || ( echo -e "\033[0;31mERROR: Failed to link SExtractor binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
ln -sf $psfex .   || ( echo -e "\033[0;31mERROR: Failed to link PSFEx binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
ln -sf $swarp .   || ( echo -e "\033[0;31mERROR: Failed to link SWarp binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
ln -sf $scamp .   || ( echo -e "\033[0;31mERROR: Failed to link Scamp binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
ln -sf $fgauss .  || ( echo -e "\033[0;31mWARNING: Failed to link fgauss binary. Path may be broken in PATHS.sh\033[0m" )
ln -sf $imcopy .  || ( echo -e "\033[0;31mERROR: Failed to link imcopy binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
ln -sf $Rscript . || ( echo -e "\033[0;31mERROR: Failed to link Rscript binary. Path may be broken in PATHS.sh\033[0m" && exit 1 )
cd ../
#}}}
# Setup preprocess scripts {{{
cd src
cp -f $scripts/doProcessPawPrint.sh .
cp -f $scripts/doProcessDetector.sh .
cp -f $scripts/doReduceDetector.r .
cp -f $scripts/makeConfigs.sh .
cp -f $scripts/makeSummaryStats.r .
cp -f $scripts/makePSF.r .
cp -f $scripts/create.weightmap.r .
cp -f $scripts/PATHS.sh .
cp -f $scripts/progressbar.sh .
cp -f $scripts/asctoldac_auto.sh .
# Do we want to keep the wget'd pawprint file? {{{
if [ "$RAWP" == "FALSE" ]
then
  if [[ -f $paws ]]
  then 
    touch removePaws.sh 
  fi 
elif [ "$RAWP" != "TRUE" ]
then 
  echo "ERROR - RAWP variable is set to an illegal value!"
  exit 1 
else 
  if [[ -f removePaws.sh ]]
  then 
    rm -f removePaws.sh 
  fi
fi
#}}}
cd ../
#}}}
#}}}
#Check that the FORCE variable is correctly set {{{
if [ "$FORCE" == "TRUE" ] 
then 
  echo -e "\033[0;34mNB:\033[0;31m FORCE variable is set to TRUE; re-reducing all images!\033[0m"
elif [ "$FORCE" == "FALSE" ] 
then
  echo -e "\033[0;34mNB:\033[0;31m FORCE variable is set to FALSE; only un-reduced files will be processed\033[0m"
else 
  echo -e "\033[0;34mERROR:\033[0;31m FORCE variable is set to an illegal value\033[0m"
  exit 2
fi 
#}}}
#Check that the UPDATE variable is correctly set {{{
if [ "$UPDATE" == "TRUE" ] 
then 
  updt=1
  echo -e "\033[0;34mNB:\033[0;31m UPDATE variable is set to TRUE; setting up run from previously completed files\033[0m"
elif [ "$UPDATE" == "FALSE" ] 
then
  updt=0
else 
  echo -e "\033[0;34mERROR:\033[0;31m UPDATE variable is set to an illegal value\033[0m"
  exit 2
fi 
#}}}
#Check for whitespace in $astrocat variable {{{
astrocat="$(echo -e "${astrocat}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
#And make sure that astrocat isn't the empty string {{{
if [ "$astrocat" == "" ]
then
  astrocat="NONE"
  extension="NONE"
else 
  extension=`echo $astrocat | awk -F '.' '{print $NF}'` 
fi
#Check if the astrocat is an ascii file 
if [ "$extension" == "asc" ]
then
  if [ -e $astrocat ]
  then
    echo -n "Converting $astrocat to FITS_LDAC:"
    newastrocat=`echo $astrocat | sed s/\.$extension/\.cat/g`
    bash ./src/asctoldac_auto.sh ./src/PATHS.sh $astrocat $newastrocat 2> AscToLDAC_LogFile.dat 
    echo " Done!"
    astrocat=$newastrocat
  fi
fi
echo "Astrocat: $astrocat"
#}}}
#}}}
#}}}

echo -e "\033[0;34m######\033[0;31mBeginning Per-Chip Preprocessing\033[0;34m#######\033[0m" #Start {{{
echo -e "\033[0;34m      \033[0;31m      (using \033[0m$nproc\033[0;31m threads)  \033[0m"
#Set commands for processing pawprints {{{
if [ $updt == 1 ]
then
  #Updating; setup frame commands {{{
  #Make sure that the Paws variable is not a file... {{{
  if [[ -f $paws ]]
  then 
    echo " - ERROR: when updating, paws must be a directory"
    exit 
  fi 
  #}}}
  #Check for incomplete paws using the lowest-level file that is being kept {{{
  if [ "$NATV" == "TRUE" ]
  then
    #Native
    n=`$Rscript --slave $scripts/nMissing.R $paws ./results/native/`
  elif [ "$UROT" == "TRUE" ]
  then
    #UnRotated
    n=`$Rscript --slave $scripts/nMissing.R $paws ./results/native_urot/`
  elif [ "$BSUB" == "TRUE" ]
  then
    #BackgroundSubtracted
    n=`$Rscript --slave $scripts/nMissing.R $paws ./results/native_bsub/`
  elif [ "$ASTC" == "TRUE" ]
  then
    #Astrometrically Corrected
    n=`$Rscript --slave $scripts/nMissing.R $paws ./results/native_astcorr/`
  else 
    #Error: There is no images set to be kept! Reducing will produce nothing!!
    echo -e "\033[0;31mERROR: Nothing has been selected for saving!! \033[0m"
    exit 1
  fi
  #}}}
  if [ $n = 0 ]
  then
    #There's nothing to do! Probably specified the wrong path...{{{
    echo " - There are no PawPrints that require reduction in that path!"
    exit 
    #}}}
  else 
    # Setup frame commands {{{
    # Note that paws will now be a directory further back because we will be in ./results/!
    cat paws2Update.dat | 
    awk -v  PAW=../$paws -v NUM=$n -v STR=$start -v NUMPROC=$nproc '{print \
    "bash ./src/doProcessPawPrint.sh",$1,PAW,NR-1,NUM,STR,NUMPROC," ;"}' > frameCommands.sh
    #}}}
  fi
  #Move to correct working directory {{{
  cd results/
  ln -sf ../frameCommands.sh ../src ../bin .
  #}}}
  #}}}
else 
  #Not updating: setup frame commands {{{
  #Write FrameDetails.dat Header {{{
  if [ "$FORCE" == "TRUE" -o ! -e frameDetails.dat ]
  then
    echo "File RAchip DECchip Filter ExpTime AirMass Extinct Naxis1 Naxis2 ZeroPoint \
PixMod HeaderSkyLevel HeaderSkyNoise HeaderSeeing MeasSeeing NPSFAccept NPSFTotal \
PostConvSeeing ConvSigma PixSize" > frameDetails.dat
  fi
  #}}}
  #Write NATV Summary Header {{{
  if [ "$FORCE" == "TRUE" -o ! -e NATV_SummaryLog.dat ]
  then
    echo File Background RMS ExtractorThres NumDetections NumSExtractions > NATV_SummaryLog.dat
  fi
  #}}}
  #Write BSUB Summary Header {{{
  if [ "$FORCE" == "TRUE" -o ! -e BSUB_SummaryLog.dat ]
  then
    echo File RA DEC PixScale NumWarnings > BSUB_SummaryLog.dat
  fi
  #}}}
  #Write UROT Summary Header {{{
  if [ "$FORCE" == "TRUE" -o ! -e UROT_SummaryLog.dat ]
  then
    echo File RA DEC PixScale NumWarnings > UROT_SummaryLog.dat
  fi
  #}}}
  #Write ASTC Summary Header {{{
  if [ "$FORCE" == "TRUE" -o ! -e ASTC_SummaryLog.dat ]
  then
    echo File RA DEC PixScale NumSWPWarnings Background RMS ExtractorThres NumDetections NumSExtractions dAXIS1 dAXIS2 Chi2 \
NumStars dAXIS1_hSNR dAXIS2_hSNR Chi2_hSNR NumStars_hSNR > ASTC_SummaryLog.dat
  fi
  #}}}
  #check whether the paw variable is a file {{{
  if [[ -f $paws ]]
  then 
    #If paws is a file, determine the number of paws to run {{{
    n=`grep -v "^#" $paws | grep -c '.fit'`
    #}}}
    if [ $n = 0 ]
    then
      #There's nothing to do! Probably specified the wrong path... {{{
      echo "ERROR - There are no PawPrints in that file!"
      exit 1
      #}}}
    fi
    # Setup frame commands {{{
    grep -v '^#' $paws | awk '{print $0" > wgetLogFile.dat 2>&1 ; mv ",$NF," ./Paws/ ; "}'  > frameX1.sh 
    grep -v '^#' $paws | awk '{print $NF}' | sed s/".fit"/" "/ | 
    awk -v  PAW=./Paws/ -v NUM=$n -v STR=$start -v NUMPROC=$nproc '{print \
    "bash ./src/doProcessPawPrint.sh",$1,PAW,NR-1,NUM,STR,NUMPROC," ; "}' > frameX2.sh
    paste frameX1.sh frameX2.sh > frameCommands.sh 
    rm -f frameX1.sh frameX2.sh 
    mkdir -p ./Paws/
    #}}}
  else 
    #If paws is a directory, determine the number of paws to run {{{
    n=`find $paws/ | grep -c '.fit'`
    #}}}
    if [ $n = 0 ]
    then
      #There's nothing to do! Probably specified the wrong path... {{{
      echo "ERROR - There are no PawPrints in that path!"
      exit 1 
      #}}}
    fi
    # Setup frame commands {{{
    find $paws | grep '.fit' | sed -r s@$paws/?@@ | sed s/".fit"/" "/ | 
    awk -v  PAW=$paws -v NUM=$n -v STR=$start -v NUMPROC=$nproc '{print \
    "bash ./src/doProcessPawPrint.sh",$1,PAW,NR-1,NUM,STR,NUMPROC ;}' > frameCommands.sh
    #}}}
  fi
  #}}}
#}}}
fi
#}}}
#Notify number of paws #{{{
echo -e "\033[0;34mThere are \033[0m$n\033[0;34m PawPrints to Reduce\033[0m "
if [ $updt == 1 ] 
then
  echo -e "\033[0;34m(UPDATE set: So only those without reductions will be listed)\033[0m "
fi
#}}}
#}}}

echo -e "\033[0;34mReducing and Renormalising PawPrints\033[0m" #{{{
if [ $n != 0 ]
then
  #Initialise the various config files {{{
  bash ./src/makeConfigs.sh 
  #}}}

  # Run frame commands {{{
  bash frameCommands.sh #2> frameCommands.log
  #}}}

  #Finalise the processing {{{
  #source the progress bar script {{{
  source ./src/progressbar.sh 
  #}}}
  # Wait here until we've finished all of the preprocessing...  {{{
  while [ `ps t | grep -v grep | grep -c doProcessPawPrint` != 0 ];
  do
    process_status doProcessDetector 16
    sleep 5
  done
  #}}}
  #Save stats and clean up the temporary files {{{
  ./bin/Rscript ./src/makeSummaryStats.r 
  #Remove config and param files {{{
  rm -f *.config *.param
  #}}}
  #Remove unwanted directories that may have been created as intermediates {{{
  if [ "$NATV" == "FALSE" ]
  then
    rm -fr native/ 
  fi
  if [ "$BSUB" == "FALSE" ]
  then
    rm -fr native_bsub/ 
  fi
  #}}}
  progressBar $n $n $start 140 
  process_status doProcessDetector 16
  #}}}
  #}}}
  
  echo -e "\n\033[0;34mFinished Individual frames\033[0m"
fi
#}}}

#echo -e "\n\033[0;34mGenerating Output Filelists\033[0m" #{{{
if [ -d native ]
then 
  find `pwd`/native/ | grep '.fits' | grep -v 'weight.fits' > native_filelist.dat
fi 
if [ -d convolved ]
then 
  find `pwd`/convolved/ | grep '.fits' | grep -v 'weight.fits' > convolved_filelist.dat
fi 
if [ -d native_bsub ]
then 
  find `pwd`/native_bsub/ | grep '.fits' | grep -v 'weight.fits' > native_bsub_filelist.dat
fi 
if [ -d native_urot ]
then 
  find `pwd`/native_urot/ | grep '.fits' | grep -v 'weight.fits' > native_urot_filelist.dat
fi 
if [ -d native_astcorr ]
then 
  find `pwd`/native_astcorr/ | grep '.fits' | grep -v 'weight.fits' > native_astcorr_filelist.dat
fi 
#}}}

# Print Completion information {{{
echo -e "\033[0;34mSummary Details:\033[0m"
echo -e "   Number of PawPrints Analysed: \033[0;34m$n\033[0m"
echo -e "   Directory paths to, and filelists of, detector files:\033[0m"
if [ -d native ]
then 
n2=`find native/ | grep '.fits' | grep -v "weight.fits" | wc | awk '{print $1}'`
echo -e "   Number of native Fits Files Generated: \033[0;34m$n2\033[0m"
echo -e "     native - \033[0;34m`pwd`/results/native/{Z,Y,J,H,Ks}/*.fits\033[0m"
echo -e "     Filelist:\033[0;34m ./results/native_filelist.dat\033[0m"
fi
if [ -d convolved ]
then 
n2=`find convolved/ | grep '.fits' | grep -v "weight.fits" | wc | awk '{print $1}'`
echo -e "   Number of convolved Fits Files Generated: \033[0;34m$n2\033[0m"
echo -e "     convolved - \033[0;34m`pwd`/results/convolved/{Z,Y,J,H,Ks}/*.fits\033[0m"
echo -e "     Filelist:\033[0;34m ./results/convolved_filelist.dat\033[0m"
fi 
if [ -d native_bsub ]
then 
n2=`find native_bsub/ | grep '.fits' | grep -v "weight.fits" | wc | awk '{print $1}'`
echo -e "   Number of background subtracted Fits Files Generated: \033[0;34m$n2\033[0m"
echo -e "     background subtracted - \033[0;34m`pwd`/results/native_bsub/{Z,Y,J,H,Ks}/*.fits\033[0m"
echo -e "     Filelist:\033[0;34m ./results/native_bsub_filelist.dat\033[0m"
fi 
if [ -d native_urot ]
then 
n2=`find native_urot/ | grep '.fits' | grep -v "weight.fits" | wc | awk '{print $1}'`
echo -e "   Number of unrotated Fits Files Generated: \033[0;34m$n2\033[0m"
echo -e "     unrotated - \033[0;34m`pwd`/results/native_urot/{Z,Y,J,H,Ks}/*.fits\033[0m"
echo -e "     Filelist:\033[0;34m ./results/native_urot_filelist.dat\033[0m"
fi 
if [ -d native_astcorr ]
then 
n2=`find native_astcorr/ | grep '.fits' | grep -v "weight.fits" | wc | awk '{print $1}'`
echo -e "   Number of astrometrically corrected Fits Files Generated: \033[0;34m$n2\033[0m"
echo -e "     astrometrically corrected - \033[0;34m`pwd`/results/native_astcorr/{Z,Y,J,H,Ks}/*.fits\033[0m"
echo -e "     Filelist:\033[0;34m ./results/native_astcorr_filelist.dat\033[0m"
fi 
#}}}

#Finalise the files {{{
if [ $updt == 1 ]
then 
  #Move back into original Detectors directory
  cd ../
else 
  #Move all the results to the results directory {{{
  mkdir -p results
  if [ -e results/native -o -e results/native_bsub -o -e results/native_urot -o -e results/native_astcorr ]
  then
    echo -e '\033[0;31mWARNING: mv will override pre-existing folders in the "./results" directory.\nBacking up all files in ./results/ to results/OLD/\033[0m'
    mkdir -p OLD
    mv results/* OLD/
    mv OLD results/
  fi
  mv -f native* frameDetails.dat results/
  if [ -e convolved ]
  then 
    mv -f convolved* results/ 
  fi 
  #}}}
fi 
#}}}

# Finished {{{
let time=(`date +%s`/60-$start)
trap : 0
echo -e "\033[0;34m###############\n\033[0;31mPreprocessing Completed (\033[0m$time\033[0;31m min elapsed)\n\033[0;34m###############\033[0m"
#}}}

