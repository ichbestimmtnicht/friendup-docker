# https://github.com/ichbestimmtnicht/docker-autobuild-release
# Template created 2020 by Ludwig Werner Döhnert
# This work is licensed under the Creative Commons Attribution 4.0 International License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/.

# Set global environment variables
ARG SRC_HUB
ARG SRC_NAME
ARG SRC_REPO
ARG SRC_TAG

FROM scratch AS buildcontext

COPY . .

# Setup arguments for next image
ARG SRC_HUB
ARG SRC_NAME
ARG SRC_REPO
ARG SRC_TAG

# Pull ubuntu image
FROM ${SRC_HUB}/amd64/${SRC_REPO}:${SRC_TAG} AS bundle

# Disable interactive questions
ENV DEBIAN_FRONTEND noninteractive

# Install Requirements
RUN apt-get update &&\
    apt-get install -y git phpmyadmin mysql-client libsqlite3-dev libsmbclient-dev libssh2-1-dev libssh-dev libaio-dev build-essential libmatheval-dev libmagic-dev libgd-dev rsync valgrind-dbg libxml2-dev php-readline cmake ssh curl build-essential python php php-cli php-gd php-imap php-mysql php-curl php-readline default-libmysqlclient-dev libsqlite3-dev libsmbclient-dev libuv-dev

# Check for Repository changes and invalidate the docker cache when there was one
ADD https://api.github.com/repos/FriendUPCloud/friendup/git/refs/heads/master friendup_version.json
ADD https://api.github.com/repos/Aperture-Development/friendup-docker/git/refs/heads/master friendup_docker_version.json
RUN mkdir /friendup
RUN git clone https://github.com/FriendUPCloud/friendup /friendup

# Copy our Entrypoint into the container and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Link libaries for the build process and build friend
RUN ln /usr/lib/x86_64-linux-gnu/libcrypto.a /friendup/libs-ext/openssl/libcrypto.a &&\
    ln /usr/lib/x86_64-linux-gnu/libssl.a /friendup/libs-ext/openssl/libssl.a
RUN cd /friendup &&\
    make setup &&\
    make compile install

# Enable interactive questions again
ENV DEBIAN_FRONTEND interactive

# Set the entrypoint for the container
ENTRYPOINT ["/entrypoint.sh"]
