#!/bin/bash

SCRIPT=$(readlink -f "$0")
# No sym
# SCRIPT=`realpath -s $0`
SCRIPTPATH=$(dirname $SCRIPT)
WORKINGDIR=$(pwd)
source ${SCRIPTPATH}/common.sh
. ./.env

DRUSH=${DRUSH:-"drush"}
COMPOSER=${COMPOSER:-"composer"}
PATH="$PATH:$PWD/vendor/bin"

[[ "$DEPLOY_BRANCH" == "" ]] && echo "Define DEPLOY_BRANCH please!" && exit 1

[ "$1" == "--export" ] && {
  langexport
  errecho "Now move ./locale to target and run this --import" >&2
  errecho "Consider to add to git via following cmd" >&2
  errecho git add locale/
  errecho 'git commit -m "Updated language"'
  errecho git push origin ${DEPLOY_BRANCH}
  errecho git checkout master
  errecho git cherry-pick --strategy=recursive -X theirs THEUPDATEDCOMMITID
}

[ "$1" == "--import" ] && {
  langimport
}
