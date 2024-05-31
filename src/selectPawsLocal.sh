#
# Script to select the appropriate Paws for analysis from a list of WFAU catalogues
# Usage:
# ./selectPawsLocal.sh <catalogues_filelist> <images_filelist> <RAcen> <DECcen> <radius> <stilts_path>
# Where:
#    <catalogues_filelist> is the file containing a list of WFAU Pawprint _CATALOGUES_ 
#    <images_filelist> is the file containing a list of WFAU Pawprint _IMAGES_ 
#    <RAcen> is the RA of the centre of the field you want to analyse
#    <DECcen> is the DEC of the centre of the field you want to analyse
#    <radius> is the radius of the field you want to analyse
#    <stilts_path> is the '/path/to/stilts'. If not supplied, it is assumed that
#                  stilts is in your $PATH
#
#  Example: To collate all paws in the UltraVISTA COSMOS 
#     bash selectPaws.sh catalogue_filelist.dat images_filelist.dat 150.1191 2.205749 1.0
#

# Set stop on error {{{
abort()
{
echo -e "\033[0;34m#####\033[0;31m  ERROR: in selectPawsLocal.sh   \033[0;34m#####\033[0m" >&2
exit 1
}
trap 'abort' 0
set -e
#}}}

#Get Variables
catalogue=$1
images=$2
racen=$3
deccen=$4
radius=$5
stilts=$6

echo -e "\033[0;34mselectPawsLocal:\033[0;31m Initialising \033[0m" >&2

if [ $# -lt 6 ]
then
  echo "Assuming STILTS is in the \$PATH..."
  stilts=`which stilts`
fi


n1=`wc $catalogue | awk '{print $1}'`
n2=`wc $images | awk '{print $1}'`


if [ $n1 -ne $n2 ]
then
  echo "Images and Catalogues file lists are not the same length!!"
  exit 2 
fi

#Setup output image-catalogue filename
imcatalogue=`echo $images | sed s/\\\\./_withData./`
echo -e "\033[0;34mselectPawsLocal:\033[0;31m Output Catalogue name is $imcatalogue \033[0m" >&2

#Setup log file
logfile='selectPaws_logfile.dat'
rm -f selectPaws_logfile.dat


#Setup the input catalogue list
grep -v "^#" $catalogue > selectPawsInput.sh

#Setup the input image list
echo grep "^#" $catalogue > $imcatalogue
echo "" > $imcatalogue

echo -e "\033[0;34mselectPawsLocal:\033[0;31m Looping over input cat... \033[0m" >&2

linenum=0
#For every line in the catalogue list:
while read line
do
  #Update the line number counter
  let linenum=$linenum+1
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
    echo $cata, N=$count
    #Good?
    if [ $count -gt 0 ]
    then
      #If so, write Image to withData file
      sed -n "${linenum}{p;q;}" $images | cat >> $imcatalogue
      #No need to keep searching
      HDU=17
    fi
    let HDU=$HDU+1
  done
  #Loop
done < selectPawsInput.sh
/bin/rm selectPawsInput.sh

trap : 0

#Finished 
