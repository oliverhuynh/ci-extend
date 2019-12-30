############################################################
# Dockerfile to test gitlab-ci
# docker image build -t gitlab-ci .
# docker container run -detach gitlab-ci
############################################################
ARG MYAPP_IMAGE=node:10.17.0-jessie
FROM $MYAPP_IMAGE
MAINTAINER Oliver Huynh
ARG HOST_SSH_PRIVATE
ARG HOST_SSH_PUBLIC
ARG SSH_HOST_CONFIG
ARG DEBUG
ARG DEPLOYDIR
WORKDIR $DEPLOYDIR
COPY . $DEPLOYDIR
RUN ln -s $DEPLOYDIR /usr/app

# Save it for debugging
RUN echo "export HOST_SSH_PRIVATE=\"$HOST_SSH_PRIVATE\"" >> .deploy-ssh
RUN echo "export HOST_SSH_PUBLIC=\"$HOST_SSH_PUBLIC\"" >> .deploy-ssh

# To sync with gitlab-ci section
RUN apt-get update
RUN apt-get install -y gettext-base rsync
RUN mkdir -p ~/.ssh
RUN echo "Setting up:$HOST_SSH_PUBLIC. $SSH_HOST_CONFIG"
RUN echo "$HOST_SSH_PUBLIC" > ~/.ssh/id_rsa.pub
RUN echo "$HOST_SSH_PRIVATE" > ~/.ssh/id_rsa
RUN printf "Host *\n\tStrictHostKeyChecking no\n\n" >> ~/.ssh/config
RUN chmod 600 ~/.ssh/*
RUN which ssh-agent || ( apt-get install -qq openssh-client )
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
RUN printf "Host deploy\n${SSH_HOST_CONFIG}" >> ~/.ssh/config
RUN if [ ! "x$DEBUG" = "x" ] ; then echo "Debugging. docker exec -ti now"; tail -f /var/log/*.log; fi
RUN bash -c ". .deploy && if [[ \"x$DEBUG\" != \"x\" ]]; then echo \"Skipping npm install\" ; else echo \"\$BUILDSCRIPT\" && eval \$BUILDSCRIPT; fi"
RUN if [ ! "x$DEBUG" = "x" ] ; then echo "Skipping git submodule update" ; else git submodule update --init --recursive --remote; git submodule sync --recursive ; fi; exit 0
RUN cat ~/.ssh/config
RUN whoami


# TODO: start-server-and-test
CMD ["sh", "-c", "tail -F /var/log/*.log"]
