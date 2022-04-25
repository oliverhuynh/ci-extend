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
source ./.env

DRUSH=${DRUSH:-"drush"}
COMPOSER=${COMPOSER:-"composer"}

# @TODO: Move to ci-extend
export GIT_PAGER=/bin/cat

lib() {
  ${COMPOSER} install
  [[ ! -d web/libraries/tabby ]] && ${DRUSH} webform:libraries:download
}

build() {
  ${SCRIPTPATH2}/drupal/build.sh
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

[[ "$(type -t $1)" == 'function' ]] && {
  callback=$1
  shift
  errecho "Executing $callback"
  $callback
  exit $?
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
  configimport $2
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
  shift
  FORCE=""
  [[ "$1" == "--force" ]] && {
    shift
    FORCE="YES"
  }

  # Verify latest lang
  CONFIGEXPORT="langexport"
  CONFIGCHECKENV=""
  export -f langexport
  CONFIGFOLDER="locale"
  checkconfig $FORCE
  isFine=$?

  # Verify latest config
  CONFIGEXPORT="configexport"
  CONFIGCHECKENV="${CONFIG_ENV}"
  export -f configexport
  CONFIGFOLDER="config/sync"
  checkconfig $FORCE
  isFine2=$?

  # Verify latest content
  CONFIGEXPORT="contentexport"
  CONFIGCHECKENV=""
  export -f contentexport
  CONFIGFOLDER="config/content"
  checkconfig $FORCE
  isFine3=$?

  [[ "${isFine}" == "1" ]] && deploycancel && exit 1
  [[ "${isFine2}" == "1" ]] && deploycancel && exit 1
  [[ "${isFine3}" == "1" ]] && deploycancel && exit 1

  gitfetch
  lib
  [[ "$DEPLOY_YARN" != "" ]] && {
    yarn install
  }
  ${DRUSH} cache-rebuild
  ${DRUSH} updatedb -y

  [[ "${isFine3}" == "2" ]] && {
    contentimport
  }

  [[ "${isFine2}" == "2" ]] && {
    configimport -y
    # 2nd try
    configimport -y
  }

  [[ "$DEPLOY_IMPORT" != "" ]] && {
    dbimport
  }

  [[ "${isFine}" == "2" ]] && {
    langimport
  }
  [[ "$DEPLOY_SOLR" != "" ]] && {
    solr
  }

  ${DRUSH} cache-rebuild
  exit $?
}

cat $0
