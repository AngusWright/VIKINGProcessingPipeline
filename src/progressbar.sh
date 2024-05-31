# call: progressBar currstate endstate starttime nchar skipped
progressBar() {


  #Colours {{{
  BLU="\033[0;34m" #Blue text
  RED="\033[0;31m" #Red text
  NC="\033[0m"     #Default text
  #}}}

  #Variables {{{
  let defcol=211*13/20
  let _start=${3}*60 #start time in seconds 
  if [ $# -lt 4 ]
  then
    _skip=0
    let nchar=$defcol
  elif [ $# -lt 5 ]
  then
    _skip=0
    nchar=${4}
  else
    let _skip=${5}
    nchar=${4}
  fi
  if [ $nchar -gt 211 ]
  then 
    nchar=211
  fi
  let  _len=40*${nchar}/$defcol   # Length of the progressbar
  _slen=`echo $_len | awk '{print "%"$0"s" }'`  # Length of the progressbar
  if [ $1 != 0 ]
  then
    #Variables2 {{{
    let _now=`date +%s`+1 # Time now in sec
    let _num1=${1}*100  # current num * 100 / n = percentage complete
    let _num2=${1}*33*${nchar}/$defcol   # current num * 33 
    let _num3=${1}*40*${nchar}/$defcol   # current num * 40 / n = number progress bar cells complete
    let _num4=${2}*39*${nchar}/$defcol   # current num * 40 >  n * 39 then number progress bar cells left = 0
    let _elap=${_now}-${_start} # Time elapsed in sec
    let _nexe=${1}-${_skip} # number already executed 
    #}}}

    #Get time remaining {{{
    if [ ${_elap} -le ${_nexe} ]
    then
      #If Time elapsed in <= number executed (ie < 1s per loop) {{{
      _avg="< 1"
      #Set togo to be (numloops - currloop) sec
      if [ ${2} -gt ${1} ]
      then
        let _togo=(${2}-${1})
      else 
        _togo=0
      fi
      #If that is more than 1 minute...
      if [ ${_togo} -gt 60 ]
      then
        #Put it in minutes! 
        let _togo=${_togo}/60
        _togo="Max ${_togo}"
      else
        #Or say there is less than 1min left. 
        _togo="Max 1"
      fi
      #}}}
    else
      #If time elapsed is > num executed (ie > 1s per loop) {{{
      let _avg=${_elap}/${_nexe}
      #Set togo to be (avg*(numloops - currloop))
      if [ ${1} -ge ${2} ]
      then 
        _togo=0 
      else 
        let _togo=(${_avg}*${2}-${_avg}*${1})
      fi
      #If that is more than 1 minute...
      if [ ${_togo} -gt 60 ]
      then
        #Put it in Minutes!
        let _togo=${_togo}/60
      else 
        #Or say there is less than 1min left. 
        _togo="Max 1"
      fi
      #}}}
    fi
    #}}}
  fi
  #}}}

  # Get the progress bar, checking for 0's {{{
  #The parameters of concern are:
  # _progress: percentage of sources finished 
  # _done: number of bar cells that are marked 'done'
  # _left: number of bar cells that are marked 'not done' 

  if [ ${1} -eq 0 -o ${2} -eq 0 ]
  then
    # Nothing done or unphysical values {{{
    _empty=$(printf "$_slen")
    printf "\r${RED}Progress : ${NC}[${_empty// /-}] 0%% (${1}/${2}) ${NC} \
${BLU}[approx. time remaining: -- min (-- sec/file)]${NC} " | awk -v NCH=$nchar '{printf "%-"NCH"s",substr($0,0,NCH)}'
    #}}}
  elif [ ${1} -ge ${2} ]
  then
    #Everything is finished! {{{
    if [ $_elap -gt 60 ] 
    then 
      let _elap=${_elap}/60
      _elap="${_elap} min"
    else 
      _elap="${_elap} sec"
    fi
    let _progress=${_num1}/${2}
    _fill=$(printf "$_slen")
    printf "\r${RED}COMPLETED! ${NC}[${_fill// /#}] ${_progress}%% (${1}/${2}) \
${BLU}[Total time elapsed: ${_elap} (${_avg} sec/file)] " | awk -v NCH=$nchar -v COL=${NC} '{printf "%-"NCH"s",substr($0,0,NCH)COL}'
    #}}}
  elif [ ${_num1} -le ${2} ]
  then
    #less than 1% completed, so catch for _progress equals 0 {{{
    _empty=$(printf "$_slen")
    printf "\r${RED}Progress : ${NC}[${_empty// /-}] 0%% (${1}/${2}) \
${BLU}[approx. time remaining: ${_togo} min (${_avg} sec/file)] " | awk -v NCH=$nchar -v COL=${NC} '{printf "%-"NCH"s",substr($0,0,NCH)COL}'
    #}}}
  elif [ ${_num2} -le ${2} ]
  then
    #less than 1 bar cell completed, so catch for _done equals 0 {{{
    let _progress=${_num1}/${2}
    _empty=$(printf "$_slen")
    printf "\r${RED}Progress : ${NC}[${_empty// /-}] ${_progress}%% (${1}/${2}) \
${BLU}[approx. time remaining: ${_togo} min (${_avg} sec/file)] " | awk -v NCH=$nchar -v COL=${NC} '{printf "%-"NCH"s",substr($0,0,NCH)COL}'
    #}}}
  elif [ ${_num3} -ge ${_num4} ]
  then
    #less than 1 bar cell remaining, so catch for _left equals 0 {{{
    let _progress=${_num1}/${2}
    _fill=$(printf "$_slen")
    printf "\r${RED}Progress : ${NC}[${_fill// /#}] ${_progress}%% (${1}/${2}) \
${BLU}[approx. time remaining: ${_togo} min (${_avg} sec/file)] " | awk -v NCH=$nchar -v COL=${NC} '{printf "%-"NCH"s",substr($0,0,NCH)COL}'
    #}}}
  else
    # All values should be in acceptable ranges; no 0s {{{
    let _progress=${_num1}/${2}
    let _done=${_num3}/${2}
    let _left=$_len-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\r${RED}Progress : ${NC}[${_fill// /#}${_empty// /-}] ${_progress}%% \
(${1}/${2}) ${BLU}[approx. time remaining: ${_togo} min (${_avg} sec/file)] " | awk -v NCH=$nchar -v COL=${NC} '{printf "%-"NCH"s",substr($0,0,NCH)COL}'
    #}}}
  fi
  #}}}

}

#call process.status ProcessName NumExpected FailedNumber
process_status() {
  #Colours {{{
  _BLU="\033[0;34m" #Blue text
  _RED="\033[0;31m" #Red text
  _NC="\033[0m"     #Default text
  _CROSS="$RED\U2718$NC"
  _BOX=" "
  _CHECK="$BLU\U2714$NC"
  #}}}
  #Only execute if there are no other process.status' running
  _count=1
  if [ $# > 2 ]
  then
    while [ `ps aux | grep -v grep | grep -c process_status` -gt 1 ]
    do 
      echo  `ps aux | grep -v grep | grep  process_status`
      sleep 1
    done
  fi
  if [ `ps au | grep -v grep | grep -c process_status` -eq 1 ]
  then 
    echo `ps aux | grep -v grep | grep -c process_status`
    #Block other process_status' from running {{{
    #touch .process_status_running
    #}}}
    #Initialise the barlength counter {{{
    let _barlen=$2+2
    #}}}
    #Check for any failed numbers {{{
    if [ $# -gt 2 ]
    then 
      _fail=$3
    else
      _fail=0
    fi
    #}}}
    #Print the open parenthesis {{{
    _n=1
    printf "["
    #}}}
    #Loop over the expected processes {{{
    _back="\b\b"
    while [ $_n -le $2 ]
    do
      _back="$_back\b"
      if [ $_n == $_fail ]
      then
          printf "$_CROSS"
      else 
        if [ "`ps t | grep $1 | grep -c " $_n$\| $_n "`" == "0" ]
        then
          #process is finished 
          printf "$_CHECK"
        else
          #process is still running 
          printf "$_BOX"
        fi
      fi
      let _n=$_n+1
    done 
    #}}}
    #print the close parenthesis and  {{{
    #Backspace to the begining of the symbols
    printf "]$_back"
    #}}}
    #Pause to ensure no overwritting, and close {{{
    #sleep 1
    #rm -f .process_status_running
    #}}}
  fi
  #Finished
}


