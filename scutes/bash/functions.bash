#!/bin/bash

alias isnum="isnumeric"
alias uppercase="upper"
alias lowercase="lower"

# Convert any lower case letters to upper case
function upper {
  if test -p /dev/stdin
  then
    data=$(</dev/stdin)
  elif test -n $1
  then
    data=$*
  else
    return 1
  fi

  echo "${data}" | tr '[a-z]' '[A-Z]'
}

# Convert any upper case letters to lower case
function lower {
  if test -p /dev/stdin
  then
    data=$(</dev/stdin)
  elif test -n $1
  then
    data=$*
  else
    return 1
  fi

  echo "${data}" | tr '[A-Z]' '[a-z]'
}

function echo2 {
  segs=()
  for c in $@
  do 
    segs[${#segs[*]}]="$(echo \"${c}\" | sed 's/\\/\\\\/g')"
  done

  eval echo ${segs[@]} >&2
}

function echo1 {
  segs=()
  for c in $@
  do 
    segs[${#segs[*]}]="$(echo \"${c}\" | sed 's/\\/\\\\/g')"
  done

  eval echo ${segs[@]} >&1
}

# Verify a specified value is a specific type
# 
#
# 
function typeof {
  if [[ -z $1 ]]
  then
    echo2 "No value type specified - expecting one of: alpha, numeric, int, float, alphanum"
    return 1
  fi

  if [[ -z $2 ]]
  then
    echo2 "No value to verify specified"
    return 1
  fi

  type="$(echo ${1} | lower)"
  val="${2}"

  case $type in
    alpha)
      pattern='^[a-zA-Z]+$'
      ;;
    numeric)
      pattern='^([0-9]+)?(\.)?[0-9]+$'
      ;;
    int)
      pattern='^[0-9]+$'
      ;;
    float)
      pattern='^[0-9]+\.[0-9]+$'
      ;;
    alphanum)
      pattern='^[a-zA-Z0-9]+$'
      ;;
    *)
      echo2 "Unknown type specified: ${type}"
      return 1
      ;;
    esac

    echo "${val}" | grep -E "${pattern}" >/dev/null

    return $?
}

function isint {
  if [[ -z $1 ]]
  then
    echo2 "No argument provided"
    return 1
  fi

  typeof int "${1}"
}

function isfloat {
  if [[ -z $1 ]]
  then
    echo2 "No argument provided" 
    return 1
  fi

  typeof float "${1}"
}

function isnumeric {
  if [[ -z $1 ]]
  then
    echo2 "No argument provided" 
    return 1
  fi

  typeof numeric "${1}"
}

function isalpha {
  if [[ -z $1 ]]
  then
    echo2 "No argument provided"
    return 1
  fi
  
  typeof alpha "${1}"
}

function isalphanum {
  if [[ -z $1 ]]
  then
    echo2 "No argument provided"
    return 1
  fi
  
  typeof alphanum "${1}"
}

function preferredps {
  if [[ -r "${user_home}/.PS${shell_lvl}" ]]
  then
    cat "${user_home}/.PS${shell_lvl}" | tr '[A-Z]' '[a-z]'
    return 0
  elif [[ -r "${user_home}/.PS" ]]
  then
    cat "${user_home}/.PS" | tr '[A-Z]' '[a-z]'
    return 0
  else
    echo "${ps_types[0]}"
  fi
}

function setps {
  if [[ -n $1 ]]
  then
    preferred=$( echo "${1}" | tr '[A-Z]' '[a-z]')
  elif [[ -n $(preferredps) ]]
  then
    preferred=$(preferredps)
  else
    echo "No PS type provided or found" 1>&2
    return 1
  fi

  # awk 'BEGIN { FS="."; } { if( match( $0, /sass/ ) && $2 == "sublime-project" ) print $1 }'
  # find /etc/profile.d -type f -exec basename {} \; | awk 'match($0, /ps-([a-zA-Z]+)(\.[bash]*)?/, res ){ print res[1] }' | tr '\n' ' '
  if [[ " ${ps_types_arr[*]} " != *" ${preferred} "* ]]; then
    echo "The PS type '${preferred}' was not found"
    return 1
  fi

  echo "Found PS type ${preferred}"
}

# Function that utilizes grep to exclude any empty lines and commented lines from a file
# Todo: ability to specify to only allow single empty lines
# Todo: verify args are files that exist
function contentonly {
  ptrn='^[[:space:]]*($|#)'
  # sed '/^$/{N;/^\n$/d;}'

  if test -p /dev/stdin
  then
    echo "$(</dev/stdin)" | grep -Ev "${ptrn}"
  elif test -n $1
  then
    grep -Ev "${ptrn}" $*
  else
    return 1
  fi
}

function app {
  [[ -z $1 ]] && return 1

  sudo lsappinfo info $(ppidof "${1}")
}

function task {
  [[ -z $1 ]] && return 1

  sudo taskinfo $(ppidof "${1}")
}

function kproc {
  [[ -z $1 ]] && return 1

  sudo lsappinfo info $(ppidof $name)
}

function ppidof {
  [[ -z $1 ]] && return 1

  pidof "${1}" | tr ' ' '\n'| sort -nr | head -n 1
}


# Parse history results, displaying records of only the commands specified. Displays a summary at the end
# Example:  cmdhistory ls awk cat
# Todo:     Should be able to search history for the commands used ANYWHERE in 
#           the command (EG: looking for wc would include the command: who | wc -l)
#
function cmdhistory {
  infrom=$(_inputfrom)

  #
  history_cmd_col=2

  if [[ $infrom == 'stdin' ]]
  then
    commands=$(</dev/stdin)
  elif [[ $infrom == 'args' ]]
  then
    commands="$*"
  else
    return 1
  fi

  commands=$(echo "${commands}" | sed 's/ /,/g')

  # If there's a custom history format defined, then use that to determine 
  # the column position of the commands
  if [[ -n $HISTTIMEFORMAT ]]; then
    history_format_cols=$(echo $HISTTIMEFORMAT | wc -w | trim)
    history_cmd_col=$(($history_cmd_col + $history_format_cols))
  fi

  history | awk -v commands="${commands}" -v cmd_col="${history_cmd_col}" -f ~/Documents/Projects/personal/carapace/awk/cmdhistory.awk
}

# Include a file if it exists
function optinc { 
  [[ -z $1 ]] && return 1

  [[ -a "${1}" ]] && . "${1}"
}

# CD into a directory, then ls -Alrth (via lh alias)
function clh { 
  cd "$@" && lh
}

# Go back n directories
function cdn { 
  [[ -z $1 ]] && return 1

  for i in `seq $1`
  do 
    cd ..
  done
}

# Extract a file using whatever needs to be used to extract that file extension
function extract {
  [[ -z $1 ]] && return 1

  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xvjf $1    ;;
      *.tar.gz)    tar xvzf $1    ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       rar x $1       ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xvf $1     ;;
      *.tbz2)      tar xvjf $1    ;;
      *.tgz)       tar xvzf $1    ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "don't know how to extract '$1'..." ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}

function whatkind {
  if [[ -z $1 ]]; then
    echo "No item specified"
    return 1
  elif [[ ! -a $1 ]]; then
    echo "No such file/directory: '$1'"
    return 1
  fi

  #echo "Checing on $1"
  /usr/bin/file --brief --no-dereference  --raw --no-buffer --mime-type "$1"
}


# Make a specified directory, then CD to said directory once its created
function mkcd {
  dir="${1}"

  #function _cd_pwd {
  #  dir="${1}"
  #   cd "${dir}" 
  #   cd_rslt=$?
  #   if [[ $? -ne 0 ]]; then
  #    echo "Failed to change the current working directory to the newly created folder ${dir} (Exited with: ${cd_rslt})"
  #    return $cd_rslt
  #  fi  
  #   echo "Directory ${dir} was created, and your pwd is now `pwd`"
  #   return 0
  #}

  # Check if it exists at all
  if [[ -a "${dir}" ]]; then

    # If it IS a directory
    if [[ -d "${dir}" ]]; then
      
      # If theres no read perms
      if [[ ! -r "${dr}" ]]; then
        echo "The directory ${dir} already exists, but you don't have read permissions, can not cd into it."
        return 1
      fi

    # $dir exists, but its not a folder..
    else
      echo "The directory ${dir} already exists, but you don't have read permissions, can not cd into it."
      return 1
    fi
  fi

  # Make the directory
  mkdir -pv "${dir}" 
  
  if [[ $mkdir_rslt -ne 0 ]]; then
    echo "failed to create the directory ${dir} (Exited with: ${mkdir_rslt})"
    return $mkdir_rslt
  fi

  cd "${dir}" 

  ec=$?

  echo "PWD: `pwd`"
}

function bashcolors {
  for fg_color in {0..7}; do
    set_foreground=$(tput setaf $fg_color)
    for bg_color in {0..7}; do
      set_background=$(tput setab $bg_color)
      echo -n $set_background$set_foreground
      printf ' F:%s B:%s ' $fg_color $bg_color
    done
    echo $(tput sgr0)
  done
}

