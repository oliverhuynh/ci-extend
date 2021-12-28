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
ARG DEPLOYDIR
RUN echo 1
COPY . /usr/ci-extend
WORKDIR /usr/ci-extend
# RUN ln -s $DEPLOYDIR /usr/app

# To sync with gitlab-ci section
RUN ./make/install

# RUN if [ ! "x$DEBUG" = "x" ] ; then echo "Debugging. docker exec -ti now"; tail -f /var/log/*.log; fi
# RUN ./make/build

# TODO: start-server-and-test
# buggy since there is not codeCMD ["bash", "-c", "./make/variables; tail -F /var/log/*.log"]

WORKDIR $DEPLOYDIR
CMD ["bash", "-c", "tail -F /var/log/*.log"]

