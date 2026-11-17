#!/bin/bash
# build.sh: rebuild the distribution's modemmanager source package with the
# patches in patches/. Runs inside a container of the target distribution
# and architecture, with this repository mounted at /work:
#
#   docker run --rm --platform linux/arm/v7 -v "$PWD:/work" ubuntu:26.04 /work/build.sh
#
# Output: /work/out/<codename>/*.deb
set -euxo pipefail
. /etc/os-release
REVISION=$(cat /work/REVISION)
OUT=/work/out/$VERSION_CODENAME
mkdir -p "$OUT"
export DEBIAN_FRONTEND=noninteractive
sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/*.sources
apt-get update -q
apt-get install -y -q --no-install-recommends dpkg-dev devscripts quilt fakeroot patch
apt-get build-dep -y -q modemmanager
BUILD=$(mktemp -d)
cd "$BUILD"
apt-get source -q modemmanager
cd modemmanager-*/
mkdir -p debian/patches
for p in /work/patches/*.patch; do
  # Each patch must apply to this distribution's version
  patch -p1 --dry-run < "$p"
  cp "$p" debian/patches/
  echo "citronics-$(basename "$p")" >> debian/patches/series
  mv "debian/patches/$(basename "$p")" "debian/patches/citronics-$(basename "$p")"
done
DEBFULLNAME="Citronics" DEBEMAIL="info@citronics.eu" \
  dch -v "$(dpkg-parsechangelog -S Version)+citronics$REVISION" -D "$VERSION_CODENAME" \
  "Apply the Citronics patches: $(cd /work/patches && ls *.patch | sed 's/^[0-9]*-//; s/\.patch$//' | paste -sd, | sed 's/,/, /g')."
DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -b -uc -us
cp ../*.deb "$OUT"/
ls -la "$OUT"
