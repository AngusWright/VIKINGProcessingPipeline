#
# doProcessDetector.sh <filename> <detector>
# 
#
#

set -e 
  #Variable Definition {{{
  #File name {{{
  file=$1
  #}}}
  #Detector number {{{
  detector=$2
  #}}}
  #Header Extension is detector number +1 {{{
  #(VISTA Paws have an empty HDU at position 1) 
  let num=($detector+1)
  #}}}
  #PATH parameters {{{
  source ./src/PATHS.sh || echo "ERROR: Failed to define variables" > ${file}_${detector}_processLog.dat
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
    astrocat=`echo $astrocat | sed s/\.$extension/\.cat/g`
  fi
  #}}}
  #}}}
  #Check that the FORCE variable is correctly set {{{
  if [ "$FORCE" == "TRUE" ] 
  then 
    frce=1
  elif [ "$FORCE" == "FALSE" ] 
  then
    frce=0
  else 
    echo -e "\033[0;34mERROR:\033[0;31m FORCE variable is set to an illegal value\033[0m"
    exit 2
  fi 
  #}}}
  #Check that the UPDATE variable is correctly set {{{
  if [ "$UPDATE" == "TRUE" ] 
  then 
    astrocat=../$astrocat
  fi 
  #}}}
  #}}}

  echo "Variables Defined" > ${file}_${detector}_processLog.dat

  #Get the Native (& convolved) maps {{{
  #Check if we need to create the convolved maps {{{
  if [ $frce == 1 ]
  then 
    #Forcing Construction (assuming we will end up keeping something!)
    status="TRUE"
  elif [ -e "./native/"*"/${file}_${detector}_r.fits" ]
  then 
    # File exists ...{{{
    if [ $frce == 1 ]
    then 
      #...but force
      echo "Making Native; file exists but forced" >> ${file}_${detector}_processLog.dat
      status="TRUE"
    else 
      #...and not forced
      status="FALSE"
    fi
    #}}}
  elif [ "$NATV" == "TRUE" ]
  then
    #File does not exist, but we want it  {{{
    echo "Making Native; file does not exist but is wanted" >> ${file}_${detector}_processLog.dat
    status="TRUE"
    #}}}
  elif [ "$BSUB" == "TRUE" -o "$UROT" == "TRUE" ]
  then
    #File does not exist, we don't want it, but... {{{
    status="FALSE"
    if [ "$BSUB" == "TRUE" -a ! -e "./native_bsub/"*"/${file}_${detector}_bsub_r.fits" ]
    then
      #...we need it for BSUB
      echo "Making Native; file is not wanted but is needed for BSUB" >> ${file}_${detector}_processLog.dat
      status="TRUE"
    fi
    if [ "$UROT" == "TRUE" -a ! -e "./native_urot/"*"/${file}_${detector}_urot_r.fits" ]
    then
      #...we need it for UROT
      echo "Making Native; file is not wanted but is needed for UROT" >> ${file}_${detector}_processLog.dat
      status="TRUE"
    fi
    #}}}
  elif [ "$ASTC" == "TRUE" ]
  then
    # File does not exist, we don't want it, and... {{{
    if [ -e "./native_astcorr/"*"/${file}_${detector}_astcorr_r.fits" ]
    then
      #We only want to make ASTC, and it already exists!
      status="FALSE"
    else 
      echo "file ./native_astcorr/*/${file}_${detector}_astcorr_r.fits does not exist" >> ${file}_${detector}_processLog.dat
      #We only want to make ASTC, and it does not exist. But ... {{{
      if [ -e "./native_bsub/"*"/${file}_${detector}_bsub_r.fits" ]
      then
        #...BSUB already exists, so we don't need it. 
        status="FALSE"
      else
        #...BSUB doesn't exist, so we need it. 
        echo "Making Native; ASTC is wanted, and neither it nor BSUB exist." >> ${file}_${detector}_processLog.dat
        status="TRUE"
      fi
      #}}}
    fi
    #}}}
  else 
    #We're not making any images!!! {{{
    echo "We're not making any outputs?!?"
    exit 2
    #}}}
  fi
  #}}}
  #If we want & need it, reduce native map {{{
  if [ "$status" == "TRUE" ]
  then
    filter=`./bin/Rscript ./src/doReduceDetector.r --no-init-file --slave --no-save \
      $file.fits $num  ${file}_${detector}_r.fits || ( awk '{ printf "ERROR: Reduction failed! Message:\n"$0"\n" }' >> ${file}_${detector}_processLog.dat )`
    if [ `echo $filter | grep -c "ERROR"` -gt 0 ]
    then
      echo -e "ERROR: Reduction failed! Message:\n$filter" >> ${file}_${detector}_processLog.dat
      exit 1
    fi
    filter=`echo $filter | awk '{print $4}'`
    mkdir -p ./native/$filter/
    mv -f ${file}_${detector}_r.fits native/$filter/ 2>> ${file}_${detector}_processLog.dat
    echo "Native file produced" >> ${file}_${detector}_processLog.dat
  else
    echo "Native file creation not needed!" >> ${file}_${detector}_processLog.dat
    #Get the filter from whichever file currently exists...
    filter=`ls ./native*/*/${file}_${detector}_*r.fits | head -1 | awk -F "/" '{print $3}'`
  fi
  if [ "$filter" == "" ] 
  then 
    echo "Filter failed to be output in loop $file_$detector!"
    exit 2
  fi
  #}}}
  #}}}

  #Generate Weightmaps for the native image {{{
  if [ "$WGTM" == "TRUE" ] 
  then
    #If we want & need it, generate weightmap {{{
    if [ $frce == 1 -o ! -e "./native/$filter/${file}_${detector}_r.weight.fits" ]
    then
      ./bin/Rscript ./src/create.weightmap.r --slave --no-init-file --no-save \
        ./native/$filter/${file}_${detector}_r.fits > ./Logs/${file}_${detector}_WgtMapLog.dat 2>&1 
    fi
    #}}}
    echo "Weightmap produced" >> ${file}_${detector}_processLog.dat
  else 
    echo "Not creating WeightMap: $WGTM != TRUE" >> ${file}_${detector}_processLog.dat
  fi
  #}}}

  #Generate Backgound Subtracted image from the native image {{{
  #Check if we need the BSUB for ASTC {{{
  if [ "$ASTC" == "TRUE" ]
  then 
    if [ -e "./native_astcorr/$filter/${file}_${detector}_astcorr_r.fits" ]
    then
      if [ $frce == 1 ]
      then
        status="TRUE"
      else
        status="FALSE"
      fi
    else
      echo "ASTCOR is wanted and does not exist. MUST make BSUB" >> ${file}_${detector}_processLog.dat
      status="TRUE"
    fi
  else
    status="FALSE"
  fi
  #}}}
  if [ "$BSUB" == "TRUE" -o "$status" == "TRUE" ] 
  then
    #If we want & need it, generate bsub image {{{
    if [ $frce == 1 -o ! -e "./native_bsub/$filter/${file}_${detector}_bsub_r.fits" ]
    then
      mkdir -p ./native_bsub/$filter/
      #Swarp the native detector {{{
      ./bin/swarp -c swarp_bsub.config -IMAGEOUT_NAME ./native_bsub/$filter/${file}_${detector}_bsub_r.fits \
        -WEIGHTOUT_NAME ./native_bsub/$filter/${file}_${detector}_bsub_r.weight.fits \
        -WEIGHT_IMAGE ./native/$filter/${file}_${detector}_r.weight.fits \
        ./native/$filter/${file}_${detector}_r.fits > ./Logs/${file}_${detector}_BSB_SwarpLog.dat 2>&1 
      echo "BackSub Map Produced" >> ${file}_${detector}_processLog.dat
      #}}}
    #}}}
    else
      echo "BackSub Map Not Produced: Already Exists!" >> ${file}_${detector}_processLog.dat
    fi
  else 
    echo "Not creating BackSub Map: BSUB $BSUB != TRUE and ( ASTC $ASTC != TRUE or already exists) " >> ${file}_${detector}_processLog.dat
  fi
  #}}}

  #Generate Unrotated image from the native image {{{
  if [ "$UROT" == "TRUE" ] 
  then
    #If we want & need it, generate bsub image {{{
    if [ $frce == 1 -o ! -e "./native_urot/$filter/${file}_${detector}_urot_r.fits" ]
    then
      mkdir -p ./native_urot/$filter/
      #Swarp the native detector {{{
      ./bin/swarp -c swarp_urot.config -IMAGEOUT_NAME ./native_urot/$filter/${file}_${detector}_urot_r.fits \
        -WEIGHTOUT_NAME ./native_urot/$filter/${file}_${detector}_urot_r.weight.fits \
        -WEIGHT_IMAGE ./native/$filter/${file}_${detector}_r.weight.fits \
        ./native/$filter/${file}_${detector}_r.fits > ./Logs/${file}_${detector}_URT_SwarpLog.dat 2>&1 
      #}}}
    fi
    #}}}
    echo "UnRotated Map Produced" >> ${file}_${detector}_processLog.dat
  else 
    echo "Not creating Unrotated Map: $UROT != TRUE" >> ${file}_${detector}_processLog.dat
  fi
  #}}}

  #Generate Astrometrically Corrected image {{{
  #Check if the astrocat is needed and exists {{{
  if [ "$astrotype" == "FILE" -a -e "$astrocat" ] 
  then 
    astrostat="TRUE"
  elif [ "$astrotype" != "FILE" ]
  then
    astrostat="TRUE"
  else
    astrostat="FALSE"
  fi
  #}}}
  if [ "$ASTC" == "TRUE" -a "$astrostat" == "TRUE" ] 
  then
    #If we want & need it, generate astcorr image {{{
    if [ $frce == 1 -o ! -e "./native_astcorr/$filter/${file}_${detector}_astcorr_r.fits" ]
    then
      #Determine the image to use for astrometric correction {{{ 
      #BSUB creation has been forced! 
      dir="./native_bsub/$filter"
      ext='_bsub'
      ##Preferentially: BSUB > UROT > Native
      #if [ "$BSUB" == "TRUE" ]
      #then
      #  dir="./native_bsub/$filter"
      #  ext='_bsub'
      #elif [ "$UROT" == "TRUE" ]
      #then
      #  dir="./native_urot/$filter"
      #  ext='_urot'
      #else
      #  dir="./native/$filter"
      #  ext=""
      #fi
      #}}}
      #Run Source Extractor over the image  {{{
      mkdir -p ./catalogues/$filter/
      ./bin/sex -c sextractor.config -CATALOG_NAME ./catalogues/$filter/${file}_${detector}_sexcat.fits \
        $dir/${file}_$detector${ext}_r.fits > ./Logs/${file}_${detector}_ACR_SExLog.dat 2>&1 

      #}}}
      if [ "$astrotype" == "FILE" ]
      then
        #Match the Source Extractor and ASTROCAT catalogues {{{
        tcount=`$stilts tmatch2 in1=./catalogues/$filter/${file}_${detector}_sexcat.fits\#2 in2=$astrocat omode=count \
          values1="ALPHA_J2000 DELTA_J2000" values2="$RAkey $DECkey" ifmt1=fits ifmt2=fits \
          matcher=sky params=2 2> ./Logs/${file}_${detector}_ACR_StiltsLog.dat | awk '{print $NF}'`
        #}}}
        #Get the number of matches {{{
        #tcount=`cat count_$detector\.txt | awk '{print $NF}'` 
        #}}}
        if [ "$tcount" == "" ]
        then
          echo "Match failed to return output! Check stilts logfile..."
          exit 1
        fi
      else 
        tcount=1000
      fi
      #If there are enough counterparts to run the AstCorr... {{{
      if [ $tcount -gt 40 ] 
      then 
        #Generate the new astrometric header using Scamp {{{
        ./bin/scamp -c scamp.config ./catalogues/$filter/${file}_${detector}_sexcat.fits > ./Logs/${file}_${detector}_ACR_ScampLog.dat 2>&1 
        #}}}
        #Move the new header to the correct filename {{{
        mv -f ./catalogues/$filter/${file}_${detector}_sexcat.head $dir/${file}_$detector${ext}_r.head 
        #}}}
        mkdir -p ./native_astcorr/$filter/headers/
        #Apply the new astrometric header using SWarp {{{
        ./bin/swarp -c swarp_urot.config -IMAGEOUT_NAME ./native_astcorr/$filter/${file}_${detector}_astcorr_r.fits \
          -WEIGHTOUT_NAME ./native_astcorr/$filter/${file}_${detector}_astcorr_r.weight.fits \
          -WEIGHT_IMAGE $dir/${file}_$detector${ext}_r.weight.fits \
          $dir/${file}_$detector${ext}_r.fits > ./Logs/${file}_${detector}_ACR_SwarpLog.dat 2>&1
        #}}}
        #Move the new header to the headers directory {{{
        mv -f $dir/${file}_$detector${ext}_r.head ./native_astcorr/$filter/headers/
        #}}}
        echo "Astrometrically Aligned Map Produced" >> ${file}_${detector}_processLog.dat
      else 
        echo "ERROR: Astrometrically Aligned Map FAILED: Not enough stars in image!" >> ${file}_${detector}_processLog.dat
      fi
      #}}}
    else 
      echo "Astrometrically Aligned Map Already exists! Skipping... " >> ${file}_${detector}_processLog.dat
    fi
    #}}}
  elif [ "$ASTC" == "TRUE" ]
  then 
    echo "ERROR: Not creating Astrometrically Aligned Map: $astrocat does not exist!" >> ${file}_${detector}_processLog.dat
    exit 1
  else 
    echo "Not creating Astrometrically Aligned Map: $ASTC != TRUE or $astrocat does not exist!" >> ${file}_${detector}_processLog.dat
  fi
  #}}}

  # Remove the unwanted/unneeded images {{{
  #Native Image {{{
  if [ "$NATV" == "FALSE" ]
  then 
    echo "Deleting the Native Images..." >> ${file}_${detector}_processLog.dat
    rm -fr native/$filter/${file}_${detector}_r*.fits
  fi 
  #}}}
  #BSUB Image {{{
  if [ "$BSUB" == "FALSE" -a "$ASTC" == "TRUE" ] 
  then 
    echo "Deleting the BSUB Images..." >> ${file}_${detector}_processLog.dat
    rm -fr native_bsub/$filter/${file}_${detector}_bsub_r*.fits
  fi 
  #}}}
  #}}}

  #Finished 
