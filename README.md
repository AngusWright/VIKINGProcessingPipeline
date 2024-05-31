# KiDS VIKING Processing Pipeline: KVpipe

Pipeline to Process VISTA VIKING Data for KiDS Photometry

Codes here taken from the private KiDS-VIKING_pipeline of Prof. H.Hildebrandt, 
where they were developed. The are duplicated here in their state at commit 
cf764ca, as used for KiDS-DR5, for public release.

---------------------------------------------------

## Scripts 

### asctoldac_auto.sh
Automatically convert ascii to ldac without need 
for creating your own config file. 

> Called by doPrepocessing.sh 


### compileInputCat.sh
Script to generate the input ASTROCAT.fits for the 
doPreprocessing.sh and doPhotometry.sh scripts, 
by selecting the appropriate KiDS catalogues. 

> Called by the user 


### create.weightmap.r
Script for creating an output weightmap to mask 
pixels where there was missing data in the original 
map.

> Called by doProcessDetector.sh


### doPreprocessing.README
Readme file for the doPreprocessing.sh script 


### doPreprocessing.sh
The main Preprocessing script. Details are given 
in the .README above. 


### doProcessDetector.sh
The script for processing a single VISTA detector  

> Called by doProcessPawPrint.sh 


### doProcessPawPrint.sh
The script for processing a single VISTA paw-print

> Called by doPreprocessing.sh 


### doReduceDetector.r
The R script for doing the pixel-crunching of each 
single detector.

> Called by doProcessDetector.sh 


### getAndGo.sh
Script to get paw-prints from the WFAU server and 
select them for processing. The script takes a 
WFAU wget script of _catalogues_ that you want to 
use to select PAWs in your field. The program 
produces N paws in the ZYJHK bands such that they 
mimic the VIKING depth across your field. 

> Called by the user


### getCatalogueDetails.sh
Get the relevant details for pawprint selection
from each of the WFAU PawPrint Catalogues. The script
uses the output logfile from selectPaws.sh to determine
the file list here, so this should be run immediately
after selectPaws, or in the same directory as it was run
prior to the catalogues being moved elsewhere...

> Called by getAndGo.sh, hereAndGo.sh


### getFrameDetails.R
Script is a side-script for the doPreprocessing.sh 
that allows a user to re-generate (most of) the 
frameDetails.dat file after processing has been 
finished. Helpful for if the frameDetails.dat file 
was lost after processing was completed. 

> Called by the user 


### getNpaws.r
Script to select the correct number of paw-prints 
needed to create a VIKING-like dataset from a list 
of WFAU paw-prints. 

> Called by getAndGo.sh, hereAndGo.sh  


### hereAndGo.sh
Script to search through paw-prints and select them
for preprocessing. The script takes a list of WFAU 
_catalogue_ files that you want to use to select 
paw-prints in your field(s). The program produces 
N paws in the ZYJHK bands such that they mimic the 
VIKING depth across your field. Different from 
getAndGo.sh in that the script requires the 
paw-print data to already exist locally. 

> Called by the user 


### makeConfigs.sh
Make the various Configure & Parameter files needed
by doProcessDetector.sh

> Called by doPreprocessing.sh


### makeEyeballMog.sh
Script for constructing a low resolution PNG of the 
fits files within the supplied directories, for 
eyeballing and QC. 

> Called by the user


### makePSF.r
Script generates a gaussian filter kernel for use 
in SourceExtractor, using parameters defined in 
the function call

> Called by doReduceDetector


### makeSummaryStats.r
Save the Summary Statistics to file and Remove all 
temporary files generated during 
doProcessDetector.sh 

> Called by doProcessPawPrint.sh, doPreprocessing.sh 


### missingDetectors.R
Script returns the entires of an input catalogue 
that are missing from a provided folder 

> Called by the user 


### nMissing.R
Returns the number of Paw-prints in an input path 
that have no matching reductions in the output path 

> Called by doPreprocessing.sh 


### PATHS.sh
Definitions of paths to various binaries required 
by the doPreprocessing.sh and doPhotometry.sh 
scripts. 
Sourced by doPreprocessing.sh, doPhotometry.sh 


### PlotProgress.R
Script shows the progress of the processing pipeline

> Called by the user 


### progressbar.sh
Shell function for printing the progress bar used 
in the processing pipeline 


### selectPawsLocal.sh
Script to select the appropriate Paws for 
preprocessing from a list of WFAU catalogues

> Called by hereAndGo.sh 


### selectPaws.sh
Script to select the appropriate Paws for 
preprocessing from a list of WFAU catalogues

> Called by getAndGo.sh 


### var_plot.R


---------------------------------------------------

```
===================================================
                 Calling Tree
===================================================

---------------------------------------------------

  #########################################
  ####  Before the main script is run: ####
  #########################################
  
  compileInputCat.sh
  
  getAndGo.sh
  -> selectPaws.sh 
  -> getCatalogueDetails.sh 
  -> getNpaws.sh 
  
  hereAndGo.sh
  -> selectPawsLocal.sh 
  -> getCatalogueDetails.sh 
  -> getNpaws.sh 
  
  #########################################
  ####         The main script         ####
  #########################################
  
  doPreProcessing.sh 
  -> makeConfigs.sh 
  -> asctoldac_auto.sh 
  -> nMissing.R 
  -> doProcessPawPrint.sh
     -> doProcessDetector.sh 
        -> doReduceDetector.r 
           -> makePSF.r 
     -> makeSummaryStats.r 
  
  #########################################
  #### While the main script is running ###
  #########################################
  
  PlotProgress.R 
  
  #########################################
  ####  After the main script has run  ####
  #########################################
  
  getFrameDetails.R
  
  makeEyeballMog.sh
  
  missingDetectors.R

```
