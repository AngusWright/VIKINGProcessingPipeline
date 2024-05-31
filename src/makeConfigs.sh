#
# makeConfigs.sh
# Make the various Congifure & Paramter files needed
# by doProcessDetector.sh
#

source ./src/PATHS.sh
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
# Generate SExtractor Config {{{
cat > sextractor.config <<- EOF
CATALOG_TYPE FITS_LDAC
PARAMETERS_NAME sextractor.param
DETECT_MINAREA 10
DETECT_THRESH 2
FILTER N
SATUR_KEY SATURATE
MAG_ZEROPOINT 30
GAIN 1
PIXEL_SCALE 0.339
WRITE_XML N
NTHREADS    1
EOF
cat > sextractor.param <<- EOF
NUMBER
X_IMAGE
Y_IMAGE
FLUX_RADIUS
FLAGS
FLUX_APER(1)
FLUXERR_APER(1)
FLUX_MAX
ELONGATION
VIGNET(50,50)
BACKGROUND
SNR_WIN
XWIN_IMAGE
YWIN_IMAGE
ERRAWIN_IMAGE
ERRBWIN_IMAGE
FLUX_AUTO
FLUXERR_AUTO
ALPHA_J2000
DELTA_J2000
A_IMAGE
B_IMAGE
KRON_RADIUS
THETA_J2000
EOF
#}}}
# Generate SCAMP Config {{{
cat > scamp.config <<- EOF
ASTREF_CATALOG     $astrotype
ASTREFCAT_NAME     $astrocat
ASTREFCENT_KEYS    $RAkey, $DECkey
ASTREFERR_KEYS     $RAERRkey, $DECERRkey, $THETAERRkey
ASTREFMAG_KEY      $MAGkey
FWHM_THRESHOLDS    0.0,10.0
SOLVE_PHOTOM       N
MATCH              N
CHECKPLOT_DEV      NULL
CHECKPLOT_TYPE     NONE 
WRITE_XML          N   
NTHREADS           1
EOF
#}}}
# Generate Bsub Swarp Config #{{{
cat > swarp_bsub.config <<- EOF
COPY_KEYWORDS  PSFSEE
SUBTRACT_BACK    Y
WRITE_XML          N   
WEIGHT_TYPE    MAP_WEIGHT
NTHREADS           1
EOF
#}}}
# Generate Urot Swarp Config #{{{
cat > swarp_urot.config <<- EOF
COPY_KEYWORDS  PSFSEE
SUBTRACT_BACK    N
WRITE_XML          N   
WEIGHT_TYPE    MAP_WEIGHT
NTHREADS           1
EOF
#}}}
# Generate PSFex Config files {{{
cat > psfex.config <<- EOF
PSF_SAMPLING 1.0
PSFVAR_DEGREES 0
PSFVAR_NSNAP 1
SAMPLE_FWHMRANGE 1.0,20.0
SAMPLE_VARIABILITY 0.75
SAMPLE_MAXELLIP 0.05
CHECKPLOT_DEV NULL
CHECKPLOT_TYPE NONE
WRITE_XML N
PSF_SIZE 55,55
SAMPLE_MINSN 20
NTHREADS 1
EOF
#}}}
# Generate PS SExtractof Config files {{{
cat > psf.sex.param <<- EOF
NUMBER
X_IMAGE
Y_IMAGE
FLUX_RADIUS
FLAGS
FLUX_APER(1)
FLUXERR_APER(1)
FLUX_MAX
ELONGATION
VIGNET(50,50)
BACKGROUND
SNR_WIN
XWIN_IMAGE
YWIN_IMAGE
ERRAWIN_IMAGE
ERRBWIN_IMAGE
FLUX_AUTO
FLUXERR_AUTO
ALPHA_J2000
DELTA_J2000
A_IMAGE
B_IMAGE
KRON_RADIUS
THETA_J2000
EOF
cat > psf.sex.config <<- EOF
CATALOG_TYPE FITS_LDAC
PARAMETERS_NAME psf.sex.param
DETECT_MINAREA 10
SATUR_KEY SATURATE
DETECT_THRESH 2
WRITE_XML N
NTHREADS 1
EOF
#}}}
