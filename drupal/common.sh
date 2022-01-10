#!/bin/bash

errecho() {
  echo $@>&2
}

envrefresh() {
  local target
  local ENVFILES
  ENVFILES=()
  [ -d env ] && {
    cd env
    ENVFILES=($(ls .${APP_ENV}.*))
    cd -
  }

  for val in ${ENVFILES[@]}; do
    target=$(echo $val | sed "s/^.${APP_ENV}._//" | sed "s/^.${APP_ENV}.//")
    errecho "cp env/$val $target"
    cp env/$val $target
  done
}

langexport() {
  mkdir locale -p
  for val in ${LANGUAGES[@]}; do
    errecho Exporting$val
    ${DRUSH} langexp --langcodes=$val --file=$PWD/locale/all-$val.po
  done
}

langimport() {
  for val in ${LANGUAGES[@]}; do
    errecho Importing$val
    ${DRUSH} langimp --langcode=$val $PWD/locale/all-$val.po
  done
}

verifyconfig() {
  [[ "${CONFIGEXPORT}" == "" ]] && errecho "Define CONFIGEXPORT callback!" && exit 1
  CONFIGFOLDER=${CONFIGFOLDER:-"config"}
  git fetch origin; 
  git remote update origin --prune;
  git fetch -p;

  # Check if previous conflic is fixed yet
  local conflict
  conflict=$(cat tmp/conflict.${CONFIGFOLDER})
  [[ "${conflict}" != "" ]] && {
    local resolved
    resolved=$(git branch -a | grep "remotes/origin/${conflict}")
    [[ "${resolved}" == "" ]] && {
      errecho "Resolved $conflict"
      rm tmp/conflict.${CONFIGFOLDER}
      echo $conflict
      return 0
    }

    [[ "${resolved}" != "" ]] && {
      errecho "Please merge $conflict then remove branch $conflict"
      echo $conflict
      return 2
    }
  } 

  errecho Get changes from DB, verify the changes ${CONFIGFOLDER}
  ${CONFIGEXPORT}
  local isChange
  git add ${CONFIGFOLDER:-"config"}
  # @TODO: Add Date: for locale diff

  isChange=$(git diff --cached ${CONFIGFOLDER:-"config"} | grep -v "Date: " | grep -v '^---'  | grep -v '^+++' | grep '^+' | head -n 1)
  git reset ${CONFIGFOLDER}
  git checkout ${CONFIGFOLDER}
  [[ "$isChange" == "" ]] && return 0
  return 1
}

storeconfig() {
  t=$(date +%s)
  ${CONFIGEXPORT}>&2
  git checkout -b dev.${t}>&2
  git add ${CONFIGFOLDER:-"config"}>&2
  git diff --cached ${CONFIGFOLDER:-"config"}>&2
  git commit -m "Latest ${CONFIGFOLDER:-"config"}">&2
  git push origin dev.${t}>&2
  git checkout ${DEPLOY_BRANCH}>&2

  echo dev.${t}
}

deploycancel() {
    local conflicts
    conflicts=($(cat tmp/conflict.* | xargs))
    local ct
    local tomerge
    local toremove
    for ct in ${conflicts[@]}; do
      tomerge="git merge origin/${ct};$tomerge"
      toremove="git push -d origin ${ct};$toremove"
    done
    errecho "Deploy is cancelled! There are changes in latest Aconfig. Please pull and merge from branch ${conflicts}! "
    errecho "[NOTE] 1. Merge latest changes in production if needed"
    errecho "git fetch origin; git pull origin ${DEPLOY_BRANCH}; git checkout ${DEPLOY_BRANCH}; ${tomerge}"
    errecho "[NOTE] 2. Resolve for the CI to merge again and deploy!"
    errecho "${toremove} git push origin ${DEPLOY_BRANCH}"
}

checkconfig() {
  [[ "${CONFIGEXPORT}" == "" ]] && errecho "Define CONFIGEXPORT callback!" && return 1
  CONFIGFOLDER=${CONFIGFOLDER:-"config"}

  # Check if there is config files changes
  [ ! -d config/sync ] && echo "CI is hardcoding config/sync. Please use this to store config files!" && return 1
  local isChange
  isChange=$(git fetch origin; git diff --name-only origin/${DEPLOY_BRANCH} ${DEPLOY_BRANCH} | grep -e "^${CONFIGFOLDER}/.*" | head -n 1)
  [[ "$isChange" == "" ]] && return 0

  local ct
  local isConfigLatest
  ct=$(verifyconfig)
  isConfigLatest=$?
  [[ "${isConfigLatest}" == "2" ]] && { 
    ct=$(echo "$ct" | tail -n 1)
    echo "$ct" > tmp/conflict.${CONFIGFOLDER}
    return 1
  }

  [[ "${isConfigLatest}" == "1" ]] && { 
    ct=$(storeconfig)
    [[ "$ct" == "" ]] && exit 1
    echo "$ct" > tmp/conflict.${CONFIGFOLDER}
    return 1
  }

  [[ "$isChange" != "" ]] && return 2
  return 0
}
