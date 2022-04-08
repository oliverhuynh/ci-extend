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

separate_config_export() {
  [[ "${CONFIG_ENV}" == "" ]] && errecho "CONFIG_ENV deployment is skipped!" && return 0
  # List files in this and copy
  local files
  files=$(ls config/sync-${CONFIG_ENV})
  local val
  val=""
  for val in ${files[@]}; do
    errecho Copying$val
    cp config/sync/$val config/sync-${CONFIG_ENV}/
    git checkout config/sync/$val
  done
}

separate_config_import() {
  [[ "${CONFIG_ENV}" == "" ]] && errecho "CONFIG_ENV deployment is skipped!" && return 0
  # List files in this and copy
  local files
  files=$(ls config/sync-${CONFIG_ENV})
  local val
  val=""
  for val in ${files[@]}; do
    [[ "$1" == "" ]] && {
      errecho Copying$val
      cp config/sync-${CONFIG_ENV}/$val config/sync/
    }
    [[ "$1" == "restore" ]] && git checkout config/sync/$val
  done
}

configexport() {
  ${DRUSH} cex -y
  separate_config_export
}

configimport() {
  separate_config_import
  ${DRUSH} cache-rebuild
  ${DRUSH} cim --preview=diff $1
  separate_config_import restore
}

contentexport() {
  [[ "${CONTENTS[@]}" == "" ]] && errecho "CONTENTS deployment is skipped!" && return 0
  local val
  val=''
  mkdir config/content -p
  for val in ${CONTENTS[@]}; do
    errecho Exporting$val
    ${DRUSH} cse --entity-types=$val --include-dependencies -y
  done
}

contentimport() {
  [[ "${CONTENTS[@]}" == "" ]] && errecho "CONTENTS deployment is skipped!" && return 0
  local val
  val=''
  for val in ${CONTENTS[@]}; do
    errecho Importing$val
    ${DRUSH} csi --entity-types=$val -y
  done
}

langexport() {
  local val
  val=''
  mkdir locale -p
  for val in ${LANGUAGES[@]}; do
    errecho Exporting$val
    ${DRUSH} langexp --langcodes=$val --file=$PWD/tmp/all-$val.po
    msguniq -s $PWD/tmp/all-$val.po > $PWD/locale/all-$val.po
  done
}

langimport() {
  local val
  val=''
  for val in ${LANGUAGES[@]}; do
    errecho Importing$val
    ${DRUSH} langimp --langcode=$val $PWD/locale/all-$val.po
  done
}

verifyconfig() {
  [[ "${CONFIGEXPORT}" == "" ]] && errecho "Define CONFIGEXPORT callback!" && exit 1
  CONFIGFOLDER=${CONFIGFOLDER:-"config/sync"}
  local CONFIGALIAS
  CONFIGALIAS=""
  CONFIGALIAS=$(echo "$CONFIGFOLDER" | sed 's/\//_/g')
  git fetch origin; 
  git remote update origin --prune;
  git fetch -p;

  # Check if previous conflict is fixed yet
  local conflict
  conflict=""
  conflict=$(cat tmp/conflict.${CONFIGALIAS})
  [[ "${conflict}" != "" ]] && {
    local resolved
    resolved=$(git branch -a | grep "remotes/origin/${conflict}")
    [[ "${resolved}" == "" ]] && {
      errecho "Resolved $conflict"
      rm tmp/conflict.${CONFIGALIAS}
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
  git add ${CONFIGFOLDER:-"config/sync"}
  [[ "${CONFIGCHECKENV}" != "" ]] && {
    git add ${CONFIGFOLDER:-"config/sync"}-${CONFIGCHECKENV}
  }
  # @TODO: Add Date: for locale diff
  local isChange
  isChange=""
  isChange=$(isFileChange ${CONFIGFOLDER:-"config/sync"})
  git reset ${CONFIGFOLDER}
  git checkout ${CONFIGFOLDER}

  local isChange2
  isChange2=""
  [[ "${CONFIGCHECKENV}" != "" ]] && {
    isChange2=$(isFileChange ${CONFIGFOLDER:-"config/sync"}-${CONFIGCHECKENV})
    git reset ${CONFIGFOLDER}-${CONFIGCHECKENV}
    git checkout ${CONFIGFOLDER}-${CONFIGCHECKENV}
  }
  [[ "$isChange" == "" ]] && [[ "${isChange2}" == "" ]] && return 0
  return 1
}

storeconfig() {
  local CONFIGALIAS
  CONFIGALIAS=""
  CONFIGALIAS=$(echo "$CONFIGFOLDER" | sed 's/\//_/g')
  t=$(date +%s)
  ${CONFIGEXPORT}>&2
  git checkout -b dev.${t}>&2
  git add ${CONFIGFOLDER:-"config"}>&2
  git diff --cached ${CONFIGFOLDER:-"config"}>&2
  [[ "${CONFIGCHECKENV}" != "" ]] && {
    git add ${CONFIGFOLDER:-"config"}-${CONFIGCHECKENV}>&2
    git diff --cached ${CONFIGFOLDER:-"config"}-${CONFIGCHECKENV}>&2
  }
  git commit -m "Latest ${CONFIGALIAS:-"config"}">&2
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
    errecho "git checkout ${DEPLOY_BRANCH}; git fetch origin; git pull origin ${DEPLOY_BRANCH}; ${tomerge}"
    errecho "[NOTE] 2. Resolve for the CI to merge again and deploy!"
    errecho "${toremove} git push origin ${DEPLOY_BRANCH}"
}

isFileChange() {
  git diff --cached $1 | grep -v "Date: " | grep -v '^---'  | grep -v '^+++' | grep '^+' | head -n 1
}

checkconfig() {
  local FORCE
  FORCE="$1"
  [[ "$1" == "YES" ]] && shift
  [[ "${CONFIGEXPORT}" == "" ]] && errecho "Define CONFIGEXPORT callback!" && return 1
  CONFIGFOLDER=${CONFIGFOLDER:-"config/sync"}

  # Check if there is config files changes
  [ ! -d ${CONFIGFOLDER} ] && echo "CI is hardcoding ${CONFIGFOLDER}. Please use this to store config files!" && return 1
  local isChange
  isChange=""
  isChange=$(git fetch origin; git diff --name-only origin/${DEPLOY_BRANCH} ${DEPLOY_BRANCH} | grep -e "^${CONFIGFOLDER}/.*" | head -n 1)
  local isChange2
  isChange2=""
  [[ "${CONFIGCHECKENV}" != "" ]] && {
    isChange2=$(git fetch origin; git diff --name-only origin/${DEPLOY_BRANCH} ${DEPLOY_BRANCH} | grep -e "^${CONFIGFOLDER}-${CONFIGCHECKENV}/.*" | head -n 1)
  }
  [[ "$isChange" == "" ]] && [[ "$isChange2" == "" ]] && return 0
  [[ "$FORCE" == "YES" ]] && echo "Forcing updating config" >&2 && return 2
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
