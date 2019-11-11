# Setup basic CI

- Setup node_modules
- Init all related modules
- Rsync
- Start the node
- Reload nginx if available

# To ur project

```
npm install --save https://github.com/antbuddy-share/gitlab-ci-extend.git
./node_modules/gitlab-ci-extend/setup.sh /etc/antbuddy/dockers/.antbuddy/onboarding/src onboarding "cd ../../ && ./docker-compose up -d onboarding && cd -"
```

Test deploy script
```

make -f ./node_modules/gitlab-ci-extend/Makefile dockerfile
docker exec -ti dp_gitlab_ci /bin/bash
export SSH_PRIVATE_KEY="privatekey"
export SSH_HOST_CONFIG="  HostName IP \# This is ssh-config"
make -f ./node_modules/gitlab-ci-extend/Makefile deploy
``
