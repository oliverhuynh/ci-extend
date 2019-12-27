#!/bin/bash

curdir=$(pwd)
d=$(dirname $0)
$d/gitlab-ci-extend --setup "$curdir" "$@"
