# syntax = docker/dockerfile:1.2
FROM archlinux

RUN echo 'Server = https://sydney.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# `makepkg` cannot (and should not) be run as root:
RUN useradd --create-home build && \
    mkdir /etc/sudoers.d/ && \
    echo "build ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/build

# Install packages
RUN --mount=type=cache,sharing=locked,target=/var/cache/pacman \
    pacman --sync --refresh --sysupgrade --noconfirm --needed \
        base-devel \
        cmake \
        git \
        rustup

# Continue execution (and `CMD`) as build:
USER build
WORKDIR /home/build/

RUN git clone https://aur.archlinux.org/android-ndk.git && cd android-ndk \
    && makepkg --syncdeps --install --noconfirm \
    && cd .. \
    && rm -rf android-ndk

COPY --chown=build:build pacman_aarch64.conf .

RUN mkdir --parents aarch64/var/lib/pacman/local/ aarch64/var/lib/pacman/sync/
RUN sudo pacman-key --config pacman_aarch64.conf --init
RUN sudo pacman-key --config pacman_aarch64.conf --recv-keys 998DE27318E867EA976BA877389CEED64573DFCA
RUN sudo pacman-key --config pacman_aarch64.conf --lsign-key 998DE27318E867EA976BA877389CEED64573DFCA

RUN rustup default stable \
    && rustup target add aarch64-linux-android
