#!/bin/bash

SCRIPT=$(readlink -f "$0")
# No sym
# SCRIPT=`realpath -s $0`
SCRIPTPATH=$(dirname $SCRIPT)
SCRIPTPATH2=$(dirname $SCRIPTPATH)
source ${SCRIPTPATH2}/drupal/common.sh
WORKINGDIR=$(pwd)

. ./.deploy
source ~/.bashrc
source ./.env
# Alway envrefresh
envrefresh


DRUSH=${DRUSH:-"drush"}
COMPOSER=${COMPOSER:-"composer"}

# @TODO: Move to ci-extend
export GIT_PAGER=/bin/cat

importconfig() {
  ${DRUSH} cache-rebuild
  ${DRUSH} cim --preview=diff $1
}


lib() {
  ${COMPOSER} install
  [[ ! -d web/libraries/tabby ]] && ${DRUSH} webform:libraries:download
}

gitfetch() {
  [[ "$DEPLOY_BRANCH" == "" ]] && echo "Define DEPLOY_BRANCH please!" && return 1
  git fetch origin 
  git pull origin -X theirs ${DEPLOY_BRANCH}
  chmod +x ./scripts/pipelines/*.sh
  return 0
}

dbimport() {
  echo Importing DB
  bash -c ./scripts/pipelines/import.sh
}

solr() {
  echo SearchIndex
  $DRUSH search-api:clear
  $DRUSH cron
}

[[ "$1" == "--solr" ]] && {
  solr
  exit $?
}

[[ "$1" == "--lib" ]] && {
  lib
  exit $?
}

[[ "$1" == "--config" ]] && {
  importconfig $2
  exit $?
}

[[ "$1" == "--git" ]] && {
  gitfetch
  exit $?
}

[[ "$1" == "--db" ]] && {
  dbimport
  exit $?
}

[[ "$1" == "--all" ]] && {
  # Verify latest lang
  CONFIGEXPORT="langexport"
  CONFIGFOLDER="locale"
  export -f langexport
  ct=$(checkconfig)
  isFine=$?

  # Verify latest config
  CONFIGEXPORT="${DRUSH} cex -y"
  CONFIGFOLDER="config"
  ct=$(checkconfig)
  isFine2=$?
  [[ "${isFine}" == "1" ]] && deploycancel && exit 1
  [[ "${isFine2}" == "1" ]] && deploycancel && exit 1

  gitfetch
  lib
  [[ "$DEPLOY_YARN" != "" ]] && {
    yarn install; 
  }
  ${DRUSH} cache-rebuild
  ${DRUSH} updatedb -y

  [[ "${isFine}" == "2" ]] && {
    importconfig -y
    # 2nd try 
    importconfig -y
  }
  [[ "$DEPLOY_IMPORT" != "" ]] && {
    dbimport
  }

  [[ "${isFine2}" == "2" ]] && {
    langimport
  }
  [[ "$DEPLOY_SOLR" != "" ]] && {
    solr
  }

  ${DRUSH} cache-rebuild
  exit $?
}

cat $0
