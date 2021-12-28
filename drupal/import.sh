#!/bin/bash

. ./.env
DRUSH=${DRUSH:-"drush"}
pv sqls/db.sql | ${DRUSH} sql-cli
