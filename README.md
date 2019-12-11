# Setup basic CI

- Setup node_modules
- Init all related modules
- Rsync
- Start the node
- Reload nginx if available

# To ur project

```
npm install --save https://github.com/antbuddy-share/gitlab-ci-extend.git

./node_modules/gitlab-ci-extend/setup.sh /etc/antbuddy/dockers/.antbuddy/onboarding/src onboarding "cp .env.dev .env && cd ../../ && ./docker-compose up --build -d onboarding && cd -"

OR

./node_modules/gitlab-ci-extend/setup.sh /etc/antbuddy/dockers/.antbuddy/onboarding/src onboarding "cd ../../ && ./docker-compose up --build -d onboarding && cd -" "cp .env.dev .env && npm install && npm run build" "12.13" "node:12.13-stretch"



./node_modules/gitlab-ci-extend/setup.sh /etc/antbuddy/dockers/.antbuddy/onboarding/src onboarding "cd ../../ && ./docker-compose up --build -d onboarding && cd -" "cp .env.dev .env && npm install && git clone ssh://git@repo.htk.me:2212/all/tech/antbuddy/react-antbuddy.git ~/react-antbuddy && cd ~/react-antbuddy && npm install && npm run build && cd - && rm -rf node_modules/react-antbuddy && mv ~/react-antbuddy ./node_modules/ && CI=false npm run build" "12.13" "node:12.13-stretch"

git clone ssh://git@repo.htk.me:2212/all/tech/antbuddy/react-antbuddy.git ~/react-antbuddy && cd ~/react-antbuddy && npm install && cd - && rm -rf node_modules/react-antbuddy && mv ~/react-antbuddy ./node_modules/ &&
```

Test deploy script  
```
export DEBUG="yes"
export SSH_PRIVATE_KEY="privatekey"
export SSH_HOST_CONFIG="  HostName IP \# This is ssh-config"
export HOST_SSH_PRIVATE="privatekey"
export HOST_SSH_PUBLIC="  HostName IP \# This is ssh-config"

make -f ./node_modules/gitlab-ci-extend/Makefile dockerfile
docker exec -ti dp_gitlab_ci /bin/bash
make -f ./node_modules/gitlab-ci-extend/Makefile deploy
``
