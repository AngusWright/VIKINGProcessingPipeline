#
# Script to generate the input ASTROCAT.fits for the doPreprocessing.sh and doPhotometry.sh 
# scripts, by selecting the appropriate KiDS catalogues 
# Usage:
# ./compileInputCat.sh </path/to/scripts/> <images_filelist> <RAcen> <DECcen> <radius> <stilts_path>
# Where:
#    </path/to/scripts/> is the path to the directory containing the pipeline scripts  
#

# Set stop on error {{{
abort()
{
echo -e "\033[0;34m#####\033[0;31m  ERROR: in compileInputCat.sh   \033[0;34m#####\033[0m" >&2
exit 1
}
trap 'abort' 0
set -e
#}}}

#Initialise {{{
echo -e "\033[0;34mcompileInputCat:\033[0;31m Initialising \033[0m" >&2
makeLDAC="TRUE"
makeCSV="FALSE"
while [ `echo $1 | grep -c '\-\-'` -ne 0 ]
do 
  if [ "$1" == "--NOLDAC" ]
  then 
    makeLDAC="FALSE"
  elif [ "$1" == "--CSV" ] 
  then
    makeCSV="TRUE"
  else 
    echo "Error: $1 is not a valid argument to ./compileInputCat.sh. Correct calling syntax is:" 
    echo "     ./compileInputCat.sh [--NOLDAC] [--CSV] </path/to/scripts/> [fieldRAmin] [fieldDECmin] [fieldRAmax] [fieldDECmax]"
    echo "  Where:"
    echo "    </path/to/scripts/> is the path to the directory containing the pipeline scripts"
    echo "    [fieldRAmin]  is optionally provided as the field minimum RA; if not included, min RA is read from PATHS.sh file"
    echo "    [fieldRAmax]  is optionally provided as the field maximum RA; if not included, max RA is read from PATHS.sh file"
    echo "    [fieldDECmin]  is optionally provided as the field minimum DEC; if not included, min DEC is read from PATHS.sh file"
    echo "    [fieldDECmax]  is optionally provided as the field maximum DEC; if not included, max DEC is read from PATHS.sh file"
    exit 1
  fi
  shift
done

#Check input arguments {{{
if [ $# -lt 1 ]
then
  echo "Error: Incorrect calling syntax! Correct syntax is:"
  echo "     ./compileInputCat.sh [--NOLDAC] [--CSV] </path/to/scripts/> [fieldRAmin] [fieldDECmin] [fieldRAmax] [fieldDECmax]"
  echo "  Where:"
  echo "    </path/to/scripts/> is the path to the directory containing the pipeline scripts"
  echo "    [fieldRAmin]  is optionally provided as the field minimum RA; if not included, min RA is read from PATHS.sh file"
  echo "    [fieldRAmax]  is optionally provided as the field maximum RA; if not included, max RA is read from PATHS.sh file"
  echo "    [fieldDECmin]  is optionally provided as the field minimum DEC; if not included, min DEC is read from PATHS.sh file"
  echo "    [fieldDECmax]  is optionally provided as the field maximum DEC; if not included, max DEC is read from PATHS.sh file"
  exit 1
elif [ $# -ne 5 ]
then
  echo "Error: Incorrect calling syntax! Correct syntax is:"
  echo "     ./compileInputCat.sh [--NOLDAC] [--CSV] </path/to/scripts/> [fieldRAmin] [fieldDECmin] [fieldRAmax] [fieldDECmax]"
  echo "  Where:"
  echo "    </path/to/scripts/> is the path to the directory containing the pipeline scripts"
  echo "    [fieldRAmin]  is optionally provided as the field minimum RA; if not included, min RA is read from PATHS.sh file"
  echo "    [fieldRAmax]  is optionally provided as the field maximum RA; if not included, max RA is read from PATHS.sh file"
  echo "    [fieldDECmin]  is optionally provided as the field minimum DEC; if not included, min DEC is read from PATHS.sh file"
  echo "    [fieldDECmax]  is optionally provided as the field maximum DEC; if not included, max DEC is read from PATHS.sh file"
  echo " $#"
  exit 1
fi
scripts=$1
#}}}
#Read the PATHS.sh file {{{
source $scripts/PATHS.sh 
if [ $# -eq 5 ]
then
  ralo=$2
  declo=$3
  rahi=$4
  dechi=$5
fi
#}}}
#}}}

#Select the relevant KiDS catalogues {{{
echo -e "\033[0;34mcompileInputCat:\033[0;31m Selecting the Relevant Catalogues \033[0m" >&2
#Command Description: 
# LINE 1: removes unwanted catalogues, and seperates out the field centre
# LINE 2: replaces the 'p' and 'm' in the coordinates with '.' and '-' respectively
# LINE 3: writes the files within the field to file
ls $InputCatsPath | grep ".cat" | grep -v "Pz_mask\|specz" | awk -F '_' '{print $0,$2,$3}' | \
   sed 's/\( m\?\)\([0-9]\+\)p\([0-9]\+\)/\1\2.\3/g' | sed 's/ m\([0-9]\+\)/ -\1/g' | \
   awk -v RA0=$ralo -v RA1=$rahi -v DEC0=$declo -v DEC1=$dechi '{if ($2>=RA0 && $2<=RA1 && $3>=DEC0 && $3<=DEC1) print $1 ;}' > selectedCatalogues.dat 
#}}}

#Combine the catalogues into a single catalogue {{{
linenum=0
n=`wc selectedCatalogues.dat | awk '{print $1}'`
let start=`date +%s`/60
source $scripts/progressbar.sh
echo -e "\033[0;34mcompileInputCat:\033[0;31m Compiling the Input Catalogue from $n individual catalogues\033[0m" >&2
#For every line in the catalogue list:
while read line
do
  #Update the line number counter
  let linenum=$linenum+1
  #Convert the catalogue entry to ASCII, selecting only the relevant keys 
  if [ $linenum -gt 1 ] 
  then 
    ldactoasc -q -i $InputCatsPath$line -t OBJECTS -k $CATAIDlab $RAkey $DECkey $RAERRkey $DECERRkey $THETAERRkey $MAGkey $THETAlab $SEMIMAJORlab $SEMIMINORlab | \
      grep -v "^#" | awk -v LN=$linenum '{print LN"_"$0}' >> ASTROCAT.asc
  else 
    ldactoasc -q -i $InputCatsPath$line -t OBJECTS -k $CATAIDlab $RAkey $DECkey $RAERRkey $DECERRkey $THETAERRkey $MAGkey $THETAlab $SEMIMAJORlab $SEMIMINORlab > ASTROCAT.asc
  fi
  progressBar $linenum $n $start
done < selectedCatalogues.dat 

echo -e "\n"

#If wanted, make the LDAC catalogue {{{
if [ "$makeLDAC" == "TRUE" ] 
then 
  echo -e "\033[0;34mcompileInputCat:\033[0;31m Converting Input Catalogue to LDAC\033[0m" >&2
  
#ASTROCAT config heredoc {{{ 
cat > ASTROCAT.config <<- EOF
# The 'asctoldac' program converts a traditional ASCII column data
# file into an LDAC table.
#
# It takes a configuration file which contains a block of information
# on each ASCII column that should be converted into an LDAC key in an
# LDAC table. 
# 
# The following configuration file applies to 'D1_r_part.asc'
COL_NAME = $CATAIDlab
COL_TTYPE = LONG
COL_HTYPE = INT
COL_COMM = "Running Object Number"
COL_UNIT = ""
COL_DEPTH = 1
#
COL_NAME = $RAkey
COL_TTYPE = DOUBLE
COL_HTYPE = FLOAT 
COL_COMM = "RA of object"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $DECkey
COL_TTYPE = DOUBLE
COL_HTYPE = FLOAT 
COL_COMM = "DEC of object"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $RAERRkey
COL_TTYPE = DOUBLE
COL_HTYPE = FLOAT 
COL_COMM = "RA uncertainty of object"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $DECERRkey
COL_TTYPE = DOUBLE
COL_HTYPE = FLOAT 
COL_COMM = "DEC uncertainty of object"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $THETAERRkey
COL_TTYPE = FLOAT
COL_HTYPE = FLOAT 
COL_COMM = "PA of skypos error ellipse"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $MAGkey
COL_TTYPE = FLOAT
COL_HTYPE = FLOAT 
COL_COMM = "MAG of object"
COL_UNIT = "mag"
COL_DEPTH = 1
#
COL_NAME = $THETAlab
COL_TTYPE = FLOAT
COL_HTYPE = FLOAT
COL_COMM = "PA of object"
COL_UNIT = "deg"
COL_DEPTH = 1
#
COL_NAME = $SEMIMAJORlab
COL_TTYPE = FLOAT
COL_HTYPE = FLOAT
COL_COMM = "Object X Position"
COL_UNIT = "pix"
COL_DEPTH = 1
#
COL_NAME = $SEMIMINORlab
COL_TTYPE = FLOAT
COL_HTYPE = FLOAT
COL_COMM = "Object X Position"
COL_UNIT = "pix"
COL_DEPTH = 1
#
EOF
#}}}
  
  asctoldac -i ASTROCAT.asc -t OBJECTS -o ASTROCAT.cat -c ASTROCAT.config > /dev/null 2>&1
fi 
#}}}

#If wanted, make the CSV catalouge {{{
if [ "$makeCSV" == "TRUE" ] 
then 
  echo "$CATAIDlab,$RAkey,$DECkey,$RAERRkey,$DECERRkey,$THETAERRkey,$MAGkey,$THETAlab,$SEMIMAJORlab,$SEMIMINORlab" > ASTROCAT.csv
  cat ASTROCAT.asc | grep -v '^#' | sed 's/  / /g' | sed 's/ /,/g' >> ASTROCAT.csv
fi
#}}}

trap : 0

#Finished 
