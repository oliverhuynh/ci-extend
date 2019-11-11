#!/bin/bash

DEPLOYDIR=$1
instance=$(basename `pwd`)
DIR=$(dirname $0)
cp $DIR/.gitlab-ci.yml ./.gitlab-ci.yml
DEPLOYDIR=$(echo $DEPLOYDIR | sed 's/\//\\\//g')

INSTANCE=${2:-$instance}
RELOADCOMMAND=${3:-'pm2 delete \\"'$INSTANCE'\\" || pm2 list; cd '$DEPLOYDIR' && pm2 start npm --name \\"'$INSTANCE'\\" -- start || pm2 list'}
RELOADCOMMAND=$(echo $RELOADCOMMAND | sed 's/\//\\\//g' | sed 's/\&/\\\&/g')
echo "RELOADCOMMAND: $RELOADCOMMAND"
sed -i 's/RELOADCOMMANDTOKEN/'"$RELOADCOMMAND"'/g' .gitlab-ci.yml
sed -i 's/INSTANCETOKEN/'"$INSTANCE"'/g' .gitlab-ci.yml
sed -i 's/DEPLOYDIRTOKEN/'"$DEPLOYDIR"'/g' .gitlab-ci.yml

echo "Remember to add SSH_PRIVATE_KEY + SSH_HOST_CONFIG (ssh-config options)"
