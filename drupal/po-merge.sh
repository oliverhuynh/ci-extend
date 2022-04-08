#!/bin/bash

fbase=$1   # The first shared ancestor in git history
flocal=$2  # Your local file
fremote=$3 # File coming from the remote
fmerge=$4  # File to write the successful merge to

function echoval() {
  echo "$@"
  eval "$@"
}

tmp=$(date +%s)
tmp="/tmp/${tmp}"
cmd="msguniq -s $flocal > $tmp.local"
echoval "$cmd"

cmd="msguniq -s $fremote > $tmp.remote"
echoval "$cmd"

cmd="msgcat -s $tmp.local $tmp.remote > $fmerge"
echoval "$cmd"

exit 0
