NAME=admin-ui
VERSION=1.0.0
SHELL:=/bin/bash

.EXPORT_ALL_VARIABLES:
	SSH_PRIVATE_KEY="$(SSH_PRIVATE_KEY)"

dockerfile:
	source .deploy && cd node_modules/gitlab-ci-extend && ./make/dockerfile $(CURDIR)

deploy:
	source .deploy && cd node_modules/gitlab-ci-extend && ./make/deploy


.PHONY: dockerfile deploy
