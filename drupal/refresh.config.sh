#!/bin/bash

. ./.deploy
. ~/.bashrc
. ./.env


[[ "$DEPLOY_BRANCH" == "" ]] && echo "Define DEPLOY_BRANCH please!">&2 && exit 1
t=$(date +%s)
DRUSH=${DRUSH:-"drush"}
${DRUSH} cex -y
git checkout -b dev.${t}
git add config
git commit -m "Latest config"
git push origin dev.${t}
git checkout ${DEPLOY_BRANCH}

echo dev.${t}
