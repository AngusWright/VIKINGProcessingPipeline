#
# This script is a sub-script within the doPreprocessing.sh script.
# As such, it will typically not need to be called directly.
# Nonetheless, correct calling syntax is:
#	 ./doProcessPawPrint.sh <fname> <paw_path> <currnum> <totnum> <starttime> <numthreads># no extension
# Where:
#	 <fname>  is the pawprint filename, _without_ the .fit extension
#	 <paw_path>  is the /path/to/pawprint/folder/
#	 <currnum> is the number of the pawprint being analysed in [0,npaws]. Used by progress bar.
#	 <totnum> is the total number of paws to analyse (npaws). Used by progress bar.
#	 <starttime> is the start time of the pawprint analysis: start = echo `date +%s`/60 | bc
#	 <numthreads> is the number of threads/processors that we want to use for this preprocessing.
#
# In the script, if $# (number of command args):
#   == 6: All variables are assumed to be here in correct order
#   == 5: numthreads is assumed to be 1, and all other command args are assumed in correct order
#   otherwise: only the first to command args are assumed present and in correct order
#

#Stop on error {{{
#abort()
#{
#mkdir -p ErrorLogs
#mv *Log.dat ErrorLogs
#echo -e "\n\033[0;34m###############################################\033[0m" >&2
#echo -e "\033[0;34m##\033[0;31m                   !FAILED!                \033[0;34m##\033[0m" >&2
#echo -e "\033[0;34m##\033[0;31m   An error occured while processing paws  \033[0;34m##\033[0m" >&2
#echo -e "\033[0;34m###############################################\033[0m" >&2 
#exit 1
#}
trap 'rm -f .process_status_running' 0
#}}}

#Functions {{{
source ./src/progressbar.sh
#}}}

# Read Command Arguments {{{
if [ $# = 6 ]
then
  total_paws=$4
  current_paw=$3
  time=$5
  numproc=$6
elif [ $# = 5 ]
then
  total_paws=$4
  current_paw=$3
  time=$5
  numproc=1
else
  total_paws=1
  current_paw=0
  let time=`date +%s`/60
fi
#}}}

# Start by decompressing the paw-print using imcopy {{{
if [ ! -e $1.fits ]
then
  ./bin/imcopy $2/$1.fit $1.fits
fi
#}}}

#Initialise Progress Bar {{{
progressBar $current_paw $total_paws $time 140 
process_status doProcessDetector 16 
#}}}

#Allow errors during loop {{{
set +e
#}}}

#Loop over detectors in this paw {{{
prompt=1
for Pawdetector in `seq 16`
do
  #if [ -e errorcode ] ;
  #then
  #  echo "ERROR: doProcessDetector.sh failed" 1>&2
  #  /bin/rm errorcode
  #  exit 2
  #fi

  #If we've exceeded the number of threads, wait {{{
  while [ `ps au | grep -v grep | grep -c doProcessPawPrint` -gt $numproc ]
  do
    #If this is the first loop of the wait, then print what is running
    if [ $Pawdetector -ge $prompt ] 
    then
      process_status doProcessDetector 16
      let prompt=$Pawdetector+1
    fi
    sleep 5
  done
  #}}}

  #Run the preprocessing of this detector, and update the progressbar on completion
  bash ./src/doProcessDetector.sh $1 $Pawdetector && (>&2 process_status doProcessDetector 16) ||  process_status doProcessDetector 16 $Pawdetector  & 
done
#}}}

#Stop on errors again {{{
set +e
#}}}

# If not running multiple cores, or if m = n; Wait here until we've finished all of the preprocessing...  {{{
let current_paw=$current_paw+1
if [ $numproc == 1 -o $total_paws == $current_paw ]
then 
  while [ `ps t | grep -v grep | grep -c doProcessDetector` -ge 1 ];
  do
    #printf "waiting...\b\b\b\b\b\b\b\b\b\b"; 
    sleep 5
  done
fi 
#}}}

# Output the results to the frameDetails.dat file {{{
#cat frameDetails_*.dat >> frameDetails.dat
#}}}
 
#Collate the logfile information & remove the temporary files {{{
./bin/Rscript ./src/makeSummaryStats.r 
#}}}


#Finished
trap : 0
