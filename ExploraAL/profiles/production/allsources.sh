#!/bin/bash
# Overrides against allsources@2d35bde for AlmaLinux 9 (candidates for upstreaming).
set -euo pipefail
cd /src/allsources

# xerces 3.2.3 moved from apache.org/dist to archive.apache.org (same MD5)
sed -i 's|https://www.apache.org/dist/xerces/|https://archive.apache.org/dist/xerces/|' xerces/CMakeLists.txt

# fftw 3.2.2: the ftp:// URL is not reachable, the same file is served over https
sed -i 's|ftp://ftp.fftw.org/pub/fftw/|https://www.fftw.org/|' fftw/CMakeLists.txt

# gsoap 2.8.82 was removed from SourceForge (only >= 2.8.135 is left, in a new directory layout).
# Only the online-monitor 3rdParty plugins use it; take the oldest release that is still available.
sed -i -e 's|gsoap-2.8/gsoap_2.8.82.zip|gsoap_2.8.135.zip/download|' \
	-e 's|3c050f02d7628811b909377b2ecc1fbe|bfabcda0f3521ec6fc753e84e399db3b|' \
	-e 's|^\tBUILD_IN_SOURCE ON|\tDOWNLOAD_NAME gsoap_2.8.135.zip\n&|' gsoap/CMakeLists.txt

# Pythia6: gcc >= 10 defaults to -fno-common (backport of allsources 3c75f08)
sed -i 's|^\tBUILD_IN_SOURCE ON|&\n\tPATCH_COMMAND sed -i "s/gcc -c -fPIC/gcc -c -fcommon -fPIC/" makePythia6.linux makePythia6.linuxg77 makePythia6.linuxgfortran|' pythia/CMakeLists.txt

# Geant4 10.7 with the system expat: Geant4PackageCache.cmake writes
# `set(EXPAT_LIBRARY ... CACHE <type>)` and EXPAT_LIBRARY is not a cache variable (empty type),
# which breaks every later find_package(Geant4). Make it one by passing it on the command line.
sed -i 's|-DGEANT4_INSTALL_DATA=ON|& -DEXPAT_LIBRARY=/usr/lib64/libexpat.so -DEXPAT_INCLUDE_DIR=/usr/include|' geant4/CMakeLists.txt
