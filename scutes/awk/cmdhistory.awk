#!/usr/bin/env awk -f

BEGIN {
  widest_cmd = 5
  cmd_all = 0
  if ( length( commands ) > 0 ){
    cmd_count = split( commands, cmd_lst, "," )
    cmd_counts[ "" ] = ""
    cmd_arr[ "" ] = ""

    for ( i=0; i<=cmd_count; i++ ){
      thiscmd = cmd_lst[ i ]
      cmd_arr[ thiscmd ] = thiscmd
      cmd_counts[ thiscmd ] = 0
    }
  }
  else {
    cmd_all = 1
  }
} 
{ 
  # Index of history record
  hist_idx = $1

  # Value in the column index specified at cmd_col
  cmd_bin = $cmd_col

  # Value of the full command (column cmd_col to the end of the line)
  cmd_full = substr($0,index($0,$cmd_col))

  if ( cmd_all || cmd_bin in cmd_arr ){
    if ( cmd_bin ~ "^[a-zA-Z0-9_./-]+$" ){
      cmd_counts[ cmd_bin ]++
      print cmd_full
      if ( length( cmd_bin ) > widest_cmd )
        widest_cmd = length( cmd_bin )
    }
  }
}
END {
  print "\nSUMMARY"
  fmt = "%"( widest_cmd + 3 )"s %s\n"

  printf fmt, "CMD", "#"
  printf fmt, "---------", "----"


  for ( cmd in cmd_counts ) {
    if ( length(cmd) == 0 ) continue
    printf fmt, cmd, cmd_counts[ cmd ]
  }
}