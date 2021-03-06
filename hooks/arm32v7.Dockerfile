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

# Setup Qemu
FROM alpine AS qemu

ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-arm.tar.gz

RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

# Setup arguments for the bundle image
ARG SRC_HUB
ARG SRC_NAME
ARG SRC_REPO
ARG SRC_TAG

# Pull image
FROM ${SRC_HUB}/arm32v7/${SRC_REPO}:${SRC_TAG} AS bundle

COPY --from=qemu qemu-arm-static /usr/bin

# Disable interactive questions
ENV DEBIAN_FRONTEND noninteractive

# Install Requirements
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        git \
        phpmyadmin \
        mysql-client \
        libsqlite3-dev \
        libsmbclient-dev \
        libssh2-1-dev \
        libssh-dev \
        libaio-dev \
        build-essential \
        libmatheval-dev \
        libmagic-dev \
        libgd-dev \
        rsync \
        valgrind-dbg \
        libxml2-dev \
        php-readline \
        cmake \
        ssh \
        curl \
        python \
        php \
        php-cli \
        php-gd \
        php-imap \
        php-mysql \
        php-curl \
        php-readline \
        default-libmysqlclient-dev \
        libsqlite3-dev \
        libsmbclient-dev \
        libuv-dev \
    && rm -rf /var/lib/apt/lists/*

# Check for Repository changes and invalidate the docker cache when there was one
ADD https://api.github.com/repos/FriendUPCloud/friendup/git/refs/heads/master friendup_version.json
ADD https://api.github.com/repos/Aperture-Development/friendup-docker/git/refs/heads/master friendup_docker_version.json
RUN mkdir /friendup
RUN git clone https://github.com/FriendUPCloud/friendup /friendup

# Copy our Entrypoint into the container and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Link libaries for the build process and build friend
RUN ln /usr/lib/arm-linux-gnueabihf/libcrypto.a /friendup/libs-ext/openssl/libcrypto.a \
    && ln /usr/lib/arm-linux-gnueabihf/libssl.a /friendup/libs-ext/openssl/libssl.a
RUN cd /friendup \
    && make setup \
    && make compile install

# Enable interactive questions again
ENV DEBIAN_FRONTEND interactive

# Set the entrypoint for the container
ENTRYPOINT ["/entrypoint.sh"]
