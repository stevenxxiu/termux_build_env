# syntax = docker/dockerfile:1.2
FROM alpine:3.19.1

# `makepkg` cannot (and should not) be run as `root`
RUN adduser -D build && \
    adduser build wheel

# Install packages
RUN apk add \
    binutils \
    cmake \
    coreutils \
    curl \
    doas \
    fakeroot \
    file \
    findutils \
    gcc \
    gcompat \
    git \
    make \
    musl-dev \
    pacman \
    patch \
    pkgconf \
    rustup

COPY doas.conf /etc/doas.d/doas.conf

WORKDIR /opt/
ENV NDK_VERSION="android-ndk-r26d"
RUN wget -O ${NDK_VERSION}.zip https://dl.google.com/android/repository/${NDK_VERSION}-linux.zip && \
    unzip ${NDK_VERSION}.zip && \
    rm ${NDK_VERSION}.zip && \
    mv ${NDK_VERSION} android-ndk

# Continue execution (and `CMD`) as build:
USER build
WORKDIR /home/build/

COPY --chown=build:build .profile pacman_aarch64.conf .

RUN mkdir --parents aarch64/var/lib/pacman/local/ aarch64/var/lib/pacman/sync/
RUN doas pacman-key --config pacman_aarch64.conf --init && \
    doas pacman-key --config pacman_aarch64.conf --recv-keys 998DE27318E867EA976BA877389CEED64573DFCA && \
    doas pacman-key --config pacman_aarch64.conf --lsign-key 998DE27318E867EA976BA877389CEED64573DFCA

RUN rustup-init -y --profile minimal --target aarch64-linux-android

COPY --chown=build:build config.toml .cargo/
