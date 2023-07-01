#!/usr/bin/nu
const container_name = 'termux_container'
const image_name = 'termux_image'

def main [package_path: path] {
  $env.DOCKER_HOST = $'unix://($env.XDG_RUNTIME_DIR)/docker.sock'

  if (do { docker images --quiet $'($image_name):latest' } | complete).stdout == '' {
    docker build --tag $image_name .
  }
  if (do { docker container inspect $container_name } | complete).exit_code == 0 {
    docker container stop $container_name
  }

  (
    docker container run
      --detach
      --rm
      --interactive
      --name $container_name
      --mount $'type=bind,source=($package_path),target=/tmp/package/'
      $image_name
  )
  (
    docker container exec $container_name
    pacman-db-upgrade --dbpath /home/build/aarch64/var/lib/pacman/
  )
  docker container exec $container_name sudo pacman --config /home/build/pacman_aarch64.conf --sync --refresh --refresh
  docker container exec --interactive --tty --workdir /tmp/package/ $container_name /bin/sh
}
