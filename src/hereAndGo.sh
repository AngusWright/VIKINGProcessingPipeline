#
# Search through the paws and select them
#
# Script takes a list of WFAU _catalogue_ files  
# that you want to use to select PAWs in your field. 
# The program produces N paws in the ZYJHK bands such 
# that they mimic the VIKING depth across your field. 
#
# Calling Syntax: 
#    bash hereAndGo.sh /path/to/scripts/
#
# Parameters are set internally (below) and in the PATHS.sh file
# 
# IMPORTANT NOTE: the file lists below must not 
# have a .sh extention, as they will be misidentified 
# as being wget scripts in getNpaws.r

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
#file containing list of WFAU _catalogues_ that you want to search through
catlist=<Catalogues_filelist>
#file containing list of WFAU _images_ that corresponds _EXACTLY_ to the catalogue list
imlist=<Images_filelist>
#RA, DEC, and Radius that you want to select in 
RAcen=<RAcen>
DECcen=<DECcen>
radius=<field radius>

#                                                                             #
# If the above parameters are set correctly, this should run without problems #
#                                                                             #

##################################
############# PATHS ##############
##################################
#Path to scripts directory
scripts=$1
#Variables from the PATHS.sh file 
source $scripts/PATHS.sh 

###################################################
############# Order of Runnng Scripts #############
###################################################

#Select the relevant Paw Prints
bash ${scripts}/selectPawsLocal.sh  ${catlist} ${imlist} ${RAcen} ${DECcen} ${radius} ${stilts}
#Get the Paw Print Observation Parameters
bash ${scripts}/getCatalogueDetails.sh $R
#Select the correct number of Paws
#per filter to match VIKING depth
$Rscript ${scripts}/getNpaws.r $imlist 
#link desired paw prints in ./SELECTED_PAWS directory
mkdir -p ./SELECTED_PAWS
finlist=`echo ${imlist} | sed s/\\\\./_withData_selected./ | sed s#^#../# |  cat`
echo $finlist
cd ./SELECTED_PAWS
ln -sf `cat ${finlist} | awk '{print "../"$1}'` . 

trap : 0

echo "###############################################################"
echo "# Setup completed. Selected paw-prints are in ./SELECTED_PAWS #"
echo "# To process pawprints, run:                                  #"
echo "  [> bash $scripts/doPreprocessing.sh $scripts ./SELECTED_PAWS/  "
echo "###############################################################"
