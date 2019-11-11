NAME=admin-ui
VERSION=1.0.0

.EXPORT_ALL_VARIABLES:
	SSH_PRIVATE_KEY="$(SSH_PRIVATE_KEY)"

dockerfile:
	. .deploy && cd node_modules/gitlab-ci-extend && ./make/dockerfile $(CURDIR)

deploy:
	. .deploy && cd node_modules/gitlab-ci-extend && ./make/deploy


.PHONY: dockerfile deploy
