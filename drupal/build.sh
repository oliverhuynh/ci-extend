#!/bin/bash

source ./.deploy
source ~/.bashrc
source ./.env

echo "Build: ${COMPILE} && ${MORECOMPILE}"
git checkout ./web
t=$PWD
cd $t && eval ${COMPILE} && cd $t && eval ${MORECOMPILE}
ret=$?
cd $t
[ ! -d tmp ] && mkdir tmp
echo $ret > ./tmp/build
exit $ret

