#
# Converts an ASCII catalogue to an LDAC catalogue 
# Syntax: 
#     bash ./asctoldac_auto.sh <PATHS.sh> <ASCII_CAT> <LDAC_CAT>
#

source $1 

#ASTROCAT config heredoc {{{ 
cat > ASTROCAT.config <<- EOF
# The 'asctoldac' program converts a traditional ASCII column data
# file into an LDAC table.
#
# It takes a configuration file which contains a block of information
# on each ASCII column that should be converted into an LDAC key in an
# LDAC table. 
# 
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

asctoldac -i $2 -t OBJECTS -o $3 -c ASTROCAT.config 
#}}}
