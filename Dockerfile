# Dummy Dockerfile because hooks aren't working with a custom Filename
# Have a look into the hooks folder to see them per arch
# https://github.com/ichbestimmtnicht/friendup-docker/tree/master/hooks/

# Download Ubuntu Image
FROM ubuntu:18.04

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
RUN ln /usr/lib/x86_64-linux-gnu/libcrypto.a /friendup/libs-ext/openssl/libcrypto.a \
    && ln /usr/lib/x86_64-linux-gnu/libssl.a /friendup/libs-ext/openssl/libssl.a
RUN cd /friendup \
    && make setup \
    && make compile install

# Enable interactive questions
ENV DEBIAN_FRONTEND interactive

# Set the entrypoint for the container
ENTRYPOINT ["/entrypoint.sh"]
