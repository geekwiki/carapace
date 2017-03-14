#! /usr/local/bin/awk -f
# https://www.gnu.org/software/gawk/manual/html_node/Strtonum-Function.html
# https://www.chemie.fu-berlin.de/chemnet/use/info/gawk/gawk_toc.html#TOC125
# https://www.chemie.fu-berlin.de/chemnet/use/info/gawk/gawk_13.html
# Functions to make
#   - join


function endwith( str, char ){
  pos = (length(str)-length(char))+1
  last = substr(str, pos)

  if ( last == char )
    return str

  return sprintf("%s%s", str, char)
}

function startwith( str, char ){
  pos = length(char)
  first = substr(str, 0, pos)

  if ( first == char )
    return str

  return sprintf("%s%s", char, str)
}

# Execute a system command, and 
function exec( cmd ){
  fullcmd = sprintf( "{ %s ; } >&1", cmd )
  fullcmd | getline result


  linecount = 0
  while ( ( cmd | getline result ) > 0 ) {
    printf "%-1s | %s\n", linecount, result
    output[ linecount ] = result
    linecount++
  } 
  close(cmd)
  printf "There were %s lines in total\n", length(output)
  return linecount
  #return join(output)
}

function error( msg ){
  cmd = sprintf("echo \"[ERROR] %s\"1>&2", msg)
  system( cmd ) 
}

# Trim left only
function ltrim(s) {
  sub( /^[ \t\r\n]+/, "", s )
  return s
}

# Trim right only
function rtrim(s) {
  sub( /[ \t\r\n]+$/, "", s )
  return s
}

# Trim left and right
function trim(s, side)  {
  #if ( )
  return rtrim(ltrim(s))
}

function ucfirst(s) {
  return toupper(substr(s, 1, 1)) tolower(substr(s, 2, length(s)-1))
}

# Debug message function
function dbg( msg ){
  # Abort function if debug isnt enabled
  if ( ! debug ) return

  # If this is the first time the debug function has been called, display the header
  if ( ! hasDebugged ){
    hasDebugged = 1
    # Only display it if nohead hasn't been set to 1 (true)
    if ( nohead != 1 )
      printf "%-2s|%-10s|%-5s|%s\n", "D","SOURCE", "LINE","MSG"
  }

  # Debug lvl 1 message format
  if ( debug == 1 )
    printf "[D] LN: %s: %s\n", FNR, msg

  # Debug lvl 2 msg format
  if ( debug >= 2 ) # "%-2s|%-10s|%-5s|%s\n"
    printf "%-2s|%-10s|%-5s|%s\n", "D",FILENAME == "-" ? "STDIN" : FILENAME, FNR, msg
}

# Function to skip to the next record if the current line is empty or commented out
function skipUseless(){
  if ( $0 ~ "^[[:space:]]*(#|;|$)" ) {
    dbg("Line is empty or commented out - skipping")
    next 
  }
}

# If the line contains a comment after some real data, then remove the comment and
# re-define $0
function clearComment(){
  if ( length( cmtfmts ) == 0 )
    return


  if ( match( $0, /^([^#;].+)(#|;)/, m ) ) { 
    dbg("\""$0"\" -> \""m[1]"\"")
    $0 = m[1] 
  }
}

function h2l(data){
  #tmpData[""]=""
  for ( d in data ){
    data[ data[d] ] = data[d]
    delete data[d]
  }
  #data=tmpData
}
function arrSwitch( data ){
  for ( d in data ){
    data[ data[d] ] = d
    delete data[d]
  }
}

# Tweak all items in a specified array
# Valid Actions:
#   - tolower   Converts each value to lower case
#               AKA: lower, lowercase, tolowercase, lower
#   - toupper   Converts each value to upper case
#               AKA: upper, uppercase, touppercase, upper
#   - ucfirst   Upper case the first letter of each value
#               AKA: uc, ucf, uppercasefirst uppercasef
#   - trim      Trims the empty spaces on both sides of each value
#   - rtrim     Trims the right side of the values
#   - ltrim     Trims the left side of the values
#   - strtonum  Executes the native strtonum() function
#   - flip      Switch the keys and values for every item
#   - fillkey   Update the keys to match the values
#   - fillval   Update the values to match the keys    
# Actions To Add:
#   - round up/down
#   - substr
#   - gsub(find, replace, str)
#   - pad values
#   - asort/asorti
#   awk '{a[$0]}END{asorti(a,b);for(i=1;i<=NR;i++)print b[i]}' f 
#   awk '{a[$0]}END{asorti(a,b,"@val_num_asc");for(i=1;i<=NR;i++)print b[i]}' f
#   http://stackoverflow.com/questions/22666799/sorting-numerically-with-awk-gawk
function tweakarray( arr, action, arg1, arg2 ){
  if ( length( arr ) == 0 || ! action )
    return

  # Standardize the action
  action = trim( tolower( action ) )

  # This determines if a case within the switch statement needs to break the 
  # parent for loop
  breakforloop = 0

  # Iterate over the array of data, using a switch statement to determine what
  # should happen to the data
  # Note: If something within the switch needs to abort the for loop, the 
  # breakforloop variable will be set to 0, and that should be checked right
  # after the switch statement at the end of the for loop (to prevent going 
  # to another iteration)
  for ( a in arr ){
    switch ( action ) {
      case /gsub/:
        if ( ! arg1 || ! arg2 ){
          dbg("Expecting two extra arguments for the action " action)
          breakforloop = 1
        }
        else {
          gsub( arg1, arg2, valarr[a])
        }
        break

      # 
      case /fill/:
        arr[ arr[a] ] = arr[a]
        delete arr[a]
        break

      # Switch key/valye
      case /(flip|swap)/:
        arr[ arr[a] ] = d
        delete arr[a]
        break

      # Upper case the FIRST letter
      case /u(pper)?c(ase)?(f(irst)?)/:
        dbg("Executing ucfirst(" arr[a] ") -> " ucfirst( arr[a] ))
        arr[a] = ucfirst( arr[a] )
        break

      # Lower case the entire string
      case /(to)?lower(case)?/:
        dbg("Executing tolower(" arr[a] ") -> " tolower( arr[a] ))
        arr[a] = tolower( arr[a] )
        break

      # Upper case the entire string
      case /(to)?upper(case)?/:
        dbg("Executing toupper(" arr[a] ") -> " toupper( arr[a] ))
        arr[a] = toupper( arr[a] )
        break

      # Trim both sides of the string
      case "trim":
        dbg("Executing trim(" arr[a] ") -> " trim( arr[a] ))
        arr[a] = trim( arr[a] )
        break

      # Trim the right side of the stirng
      case "rtrim":
        dbg("Executing rtrim(" arr[a] ") -> " rtrim( arr[a] ))
        arr[a] = rtrim( arr[a] )
        break

      # Trim the left side of the string
      case "ltrim":
        dbg("Executing ltrim(" arr[a] ") -> " ltrim( arr[a] ))
        arr[a] = ltrim( arr[a] )
        break

      # Convert any numerical strings to integers
      case "strtonum":
        dbg("Executing strtonum(" arr[a] ") -> " strtonum( arr[a] ))
        arr[a] = strtonum( arr[a] )
        break

      # Somebody made a boo boo
      default:
        dbg("Invalid action specified: " action " - leaving value unmodified -> " arr[a])
        # Abort the for loop
        breakforloop = 1
        break
    }

    # If one of the actions set the breakforloop to true, then abort the for loop
    if ( breakforloop == 1 ){
      dbg("Aborting for loop in tweakedarray on item #" d)
      break
    }
  }
}
