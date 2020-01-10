#!/bin/bash

# Taken from https://lobradov.github.io/Building-docker-multiarch-images/
# Could probably do with a tidy up

for docker_arch in amd64 arm32v6 arm64v8; do
  case ${docker_arch} in
    amd64   ) qemu_arch="x86_64" ;;
    arm32v6 ) qemu_arch="arm" ;;
    arm64v8 ) qemu_arch="aarch64" ;;    
  esac
  cp Dockerfile.cross Dockerfile.${docker_arch}
  sed -i "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
  sed -i "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile.${docker_arch}
  if [ ${docker_arch} == 'amd64' ]; then
    sed -i "/__CROSS_/d" Dockerfile.${docker_arch}
  else
    sed -i "s/__CROSS_//g" Dockerfile.${docker_arch}
  fi
done

for arch in amd64 arm32v6 arm64v8; do
  docker build -f Dockerfile.${arch} -t peteward44/godaddy-ddns:${arch}-latest .
  docker push peteward44/godaddy-ddns:${arch}-latest
done

docker manifest create peteward44/godaddy-ddns:latest peteward44/godaddy-ddns:amd64-latest peteward44/godaddy-ddns:arm32v6-latest peteward44/godaddy-ddns:arm64v8-latest
docker manifest annotate peteward44/godaddy-ddns:latest peteward44/godaddy-ddns:arm32v6-latest --os linux --arch arm
docker manifest annotate peteward44/godaddy-ddns:latest peteward44/godaddy-ddns:arm64v8-latest --os linux --arch arm64 --variant armv8
docker manifest push peteward44/godaddy-ddns:latest

