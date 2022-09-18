#!/usr/bin/env bash

set -e

case ${1#linux/} in
386)
  TINI_PLATFORM=i386
  ;;
arm/v7)
  TINI_PLATFORM=armhf
  ;;
arm/v6)
  TINI_PLATFORM=armel
  ;;
*)
  TINI_PLATFORM=${1#linux/}
  ;;
esac

echo "Installing tini for $TINI_PLATFORM"

wget "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TINI_PLATFORM}" -O /tini
wget "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TINI_PLATFORM}.asc" -O /tini.asc

chmod +x /tini

apk add gnupg
gpg --import </tmp/docker/tini.pubkey.gpg
gpg --batch --verify /tini.asc /tini
apk del gnupg
