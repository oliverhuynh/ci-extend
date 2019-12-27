#!/bin/bash

curdir=$(pwd)
d=$(dirname $0)
cd $d
./gitlab-ci-extend --setup "$curdir" "$@"
