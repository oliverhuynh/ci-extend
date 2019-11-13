#!/bin/bash

DEPLOYDIR=$1
instance=$(basename `pwd`)
DIR=$(dirname $0)
cp $DIR/.gitlab-ci.yml ./.gitlab-ci.yml
cp $DIR/.deploy ./
DEPLOYDIR=$(echo $DEPLOYDIR | sed 's/\//\\\//g')

INSTANCE=${2:-$instance}
RELOADCOMMAND=${3:-'pm2 delete \\"'$INSTANCE'\\" || pm2 list; cd '$DEPLOYDIR' && pm2 start npm --name \\"'$INSTANCE'\\" -- start || pm2 list'}
RELOADCOMMAND=$(echo $RELOADCOMMAND | sed 's/\//\\\//g' | sed 's/\&/\\\&/g')
echo "RELOADCOMMAND: $RELOADCOMMAND"

BUILDSCRIPT=${4:-'npm install;'}
BUILDSCRIPT=$(echo $BUILDSCRIPT | sed 's/\//\\\//g' | sed 's/\&/\\\&/g')
echo "BUILDSCRIPT: $BUILDSCRIPT"

sed -i 's/RELOADCOMMANDTOKEN/'"$RELOADCOMMAND"'/g' .gitlab-ci.yml
sed -i 's/INSTANCETOKEN/'"$INSTANCE"'/g' .gitlab-ci.yml
sed -i 's/DEPLOYDIRTOKEN/'"$DEPLOYDIR"'/g' .gitlab-ci.yml
sed -i 's/BUILDSCRIPTTOKEN/'"$BUILDSCRIPT"'/g' .gitlab-ci.yml


sed -i 's/RELOADCOMMANDTOKEN/'"$RELOADCOMMAND"'/g' .deploy
sed -i 's/INSTANCETOKEN/'"$INSTANCE"'/g' .deploy
sed -i 's/DEPLOYDIRTOKEN/'"$DEPLOYDIR"'/g' .deploy
sed -i 's/BUILDSCRIPTTOKEN/'"$BUILDSCRIPT"'/g' .deploy

echo "Remember to add SSH_PRIVATE_KEY + SSH_HOST_CONFIG (ssh-config options)"
