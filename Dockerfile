############################################################
# Dockerfile to test gitlab-ci
# docker image build -t gitlab-ci .
# docker container run -detach gitlab-ci
############################################################

FROM node:10.17.0-jessie
MAINTAINER Oliver Huynh

WORKDIR /usr/app
COPY . /usr/app
RUN apt-get update
RUN apt-get install -y gettext-base rsync
RUN mkdir -p ~/.ssh
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
RUN git submodule update --init --recursive --remote
RUN npm install

# TODO: start-server-and-test
CMD ["sh", "-c", "tail -F /var/log/*.log"]
