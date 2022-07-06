# Init

Quick

```
curl -o- https://raw.githubusercontent.com/oliverhuynh/ci-extend/master/make/install | bash -s -- quick
```

Full with DrupalCI

```
curl -o- https://raw.githubusercontent.com/oliverhuynh/ci-extend/master/make/install | bash
```

Check .example.gitlabci.yml for reference

# OS requirements

```
Debian
```

# Git requirements

```
Ensure your git is clean
```

# Setup basic CI

- Setup node_modules
- Init all related modules
- Rsync
- Start the node
- Reload nginx if available

# How this work

This will add gitlab-ci.yml to your project and do following steps for the CI:

- exec BUILDSCRIPT in .deploy
- Download git submodules
- Rsync builts to target server
- Install specified node version in target server and use the node version
- Exec RELOADCOMMAND in DEPLOYDIR

# To setup ur project

Test deploy script

- Script will rsync code to server with following config:

```
export DEBUG="yes"
export SSH_HOST_CONFIG="  HostName IP \# This is ssh-config"
```

- Script will do git pull via following credential

```
export HOST_SSH_PRIVATE="privatekey"
export HOST_SSH_PUBLIC="publickey"
```

- Exec above commands and run following command to test deploy script

```
make -f ./node_modules/gitlab-ci-extend/Makefile dockerfile
docker exec -ti dp_gitlab_ci /bin/bash
make -f ./node_modules/gitlab-ci-extend/Makefile deploy
``

# Quicker CI
- Build the docker image with your desired. Example
```

cd [YOUR drupal-docker project with .env]

# TARGET is where you're running gitlab runner

export TARGET=cc-local2.jufist.org export CI_EXTENDPATH=~/projects/ci-extend export
MYAPP_IMAGE=marcelovani/drupalci:9-apache-interactive export CI_IMAGE=ci-extend/drupalci:9-apache-interactive
${CI_EXTENDPATH:-"."}/make/dockerfile

```
- Add the docker policy to your gitlab runner as https://stackoverflow.com/a/43481746
```

vi /etc/gitlab-runner/config.toml [runners.docker] pull_policy = "if-not-present"

```
$DRUSH csi --entity-types=menu_link_content
--entity-types=taxonomy_term
```
