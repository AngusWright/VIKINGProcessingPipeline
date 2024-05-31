#
# Script to select the appropriate Paws for analysis from WFAU database
# Usage:
# ./selectPaws.sh <wgetscript> <RAcen> <DECcen> <radius> <stilts_path>
# Where:
#    <wgetscript> is the filename of the WFAU Pawprint _CATALOGUES_ wget script
#    <RAcen> is the RA of the centre of the field you want to analyse
#    <DECcen> is the DEC of the centre of the field you want to analyse
#    <radius> is the radius of the field you want to analyse
#    <stilts_path> is the '/path/to/stilts'. If not supplied, it is assumed that
#                  stilts is in your $PATH
#
#  Example: To collate all paws in the VIDEO CDFS
#     bash selectPaws.sh VIDEO_CDFS_CATALOGUES_wget.sh  53.09722 -27.81014 0.27
#



#Get Variables
script=$1
racen=$2
deccen=$3
radius=$4
stilts=$5

if [ $# -lt 5 ]
then
  echo "Assuming STILTS is in the \$PATH..."
  stilts=`which stilts`
fi

echo $stilts

#Setup image wget script filename
imscript=`echo $script | sed s/.sh/_Images.sh/`

#Setup log file
logfile='selectPaws_logfile.dat'
rm -f selectPaws_logfile.dat

#Setup the wget script
grep -v "^#" $script > selectPawsInput.sh

#Setup the image wget script
grep "^#" $script > $imscript

#For every line in the wget script:
while read line
do
  #Check if the catalogue file already exists (which means it must be good)
  if [ ! -e "`echo $line | awk '{print $NF}'`" ] 
  then
    #Get the catalogue
    echo eval "$line" >> $logfile
    eval "$line" >> $logfile 2>&1

    HDU=1
    #Loop through HDUs
    while [ $HDU -le 16 ]
    do
      #Check the RA/DEC limits of the sources
      cata=`echo $line | awk -v hdu=$HDU '{print $NF"#"hdu}'`

      #Setup the stilts command
      stiltscom=`echo $stilts tpipe in=$cata cmd=\"select \'skyDistanceDegrees\(RA*180/PI,DEC*180/PI, $racen,$deccen\) \< $radius\'\" omode=count `

      #Get the count
      count=`eval "$stiltscom" | awk '{print $NF}'`
      #Write file details to stdout and logfile
      echo $cata, N=$count >> $logfile
      echo -n -e "\r$cata, N=$count"
      #Good?
      if [ $count -gt 0 ]
      then
        #If so, write Image WGet
        echo $line | sed s/_cat//g | sed s/\\.fits/.fit/g >> $imscript
        #No need to keep searching
        HDU=17
      fi
      let HDU=$HDU+1
    done
    #If not good, remove catalogue file
    if [ $count -eq 0 ]
    then
      cata=`echo $line | awk '{print $NF}'`
      rm $cata
    fi
  else 
    #Write a dummy line to the logfile: 
    cata=`echo $line | awk -v hdu=1 '{print $NF"#"hdu}'`
    echo $cata, N=999999 >> $logfile
    echo $line | sed s/_cat//g | sed s/\\.fits/.fit/g >> $imscript
    echo -n -e "\r$cata, PREVIOUSLY OK\'d"
  fi
  #Loop
done < selectPawsInput.sh
/bin/rm selectPawsInput.sh
