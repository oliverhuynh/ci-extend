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

```
npm install --save https://github.com/antbuddy-share/gitlab-ci-extend.git

./node_modules/gitlab-ci-extend/setup.sh /path/to/proj/src onboarding "cp .env.dev .env && cd ../../ && ./docker-compose up --build -d onboarding && cd -"

OR

./node_modules/gitlab-ci-extend/setup.sh /path/to/proj/src onboarding "cd ../../ && ./docker-compose up --build -d onboarding && cd -" "cp .env.dev .env && npm install && npm run build" "12.13" "node:12.13-stretch"



./node_modules/gitlab-ci-extend/setup.sh /path/to/proj/src onboarding "cd ../../ && ./docker-compose up --build -d onboarding && cd -" "cp .env.dev .env && npm install && CI=false npm run build" "12.13" "node:12.13-stretch"
```

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
