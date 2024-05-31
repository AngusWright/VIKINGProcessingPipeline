#
# Get the paws from WFAU and select them
#
# Script takes a WFAU wget script of _catalogues_ 
# that you want to use to select PAWs in your field. 
# The program produces N paws in the ZYJHK bands such 
# that they mimic the VIKING depth across your field. 
#
# Calling Syntax: 
#    bash getAndGo.sh /path/to/scripts
#
# Parameters are set internally (below) and in the PATHS.sh file
# Example Observation parameters for CDFS:
# wgetscr=VIDEO_CDFS_CATALOGUES_wget.sh
# RAcen=53.4
# DECcen=-27.55
# radius=0.6
# 

# Set stop on error {{{
abort()
{
echo -e "\033[0;34m###############################################\033[0m" >&2
echo -e "\033[0;34m##\033[0;31m                   !FAILED!                \033[0;34m##\033[0m" >&2
echo -e "\033[0;34m##\033[0;31m              An error occured             \033[0;34m##\033[0m" >&2
echo -e "\033[0;34m###############################################\033[0m" >&2 
exit 1
}
trap 'abort' 0
set -e
#}}}

#########################################################
############# Observation Selection Details #############
#########################################################
#WFAU wget script for _catalogues_ that you want to search through
wgetscr=results13_10_1_38_22960_cats.sh
#RA, DEC, and Radius that you want to select in 
RAcen=36.6
DECcen=-4.5 
radius=0.6

#                                                                             #
# If the above parameters are set correctly, this should run without problems #
#                                                                             #

#Check correct calling syntax {{{
if [ $# -ne 1 ]
then
  echo "Incorrect calling syntax. Correct usage is:"
  echo "   bash /path/to/getAndGo.sh </path/to/scripts> "
fi
#}}}

echo -e "\033[0;34m#######################################################\033[0m"
echo -e "\033[0;34m#\033[0;31m    Performing Setup and Selection of paw-prints     \033[0;34m#\033[0m"
echo -e "\033[0;34m#######################################################\033[0m"

##################################
############# PATHS ##############
##################################
echo "Sourcing the PATHS script from $1 "
#Path to scripts directory
scripts=$1
#Variables from the PATHS.sh file 
source $scripts/PATHS.sh || echo -e "\033[0;31m ERROR: source of PATHS.sh failed. Some paths likely returned value 1\033[0m"
#Copy needed files to ./src/
mkdir -p ./src/
cp -f $scripts/selectPaws.sh ./src/
cp -f $scripts/getCatalogueDetails.sh ./src/
cp -f $scripts/getNpaws.r ./src/
cp -f $scripts/progressbar.sh ./src/

###################################################
############# Order of Runnng Scripts #############
###################################################

echo "Selecting Pawprints that are in the region requested... "
#Select the relevant Paw Prints
bash ./src/selectPaws.sh  ${wgetscr} ${RAcen} ${DECcen} ${radius} "${stilts}"
#Get the Paw Print Observation Parameters
echo "Getting details of the paw-prints... "
bash ./src/getCatalogueDetails.sh ./src/ $R
#Select the correct number of Paws
#per filter to match VIKING depth
echo "Selecting the correct number of paws..."
$Rscript ./src/getNpaws.r $wgetscr 
#Move the catalogues to the Catalogues directory
mkdir -p Catalogues Paws
mv *_cat.fits Catalogues
#Get the selected Images from WFAU
echo "Transferring the Images with wget..."
bash `echo ${wgetscr} | sed s/\.sh/_Images_selected.sh/` 2>&1 > wget_Logfile.dat 
mv *.fit Paws/

trap : 0

echo -e "\033[0;34m#######################################################\033[0m"
echo -e "\033[0;34m#\033[0;31m Setup completed. Selected paw-prints are in ./Paws/ \033[0;34m#\033[0m"
echo -e "\033[0;34m#\033[0;31m To process pawprints, run:                          #\033[0m"
echo -e "  [> bash $scripts/doPreprocessing.sh $scripts ./Paws/ "
echo -e "\033[0;34m#######################################################\033[0m"
