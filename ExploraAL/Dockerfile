# ExploraAL: TpcExplora development image on AlmaLinux
# (allsources + GenFit + explora + all 3rdParty plugins, including the private ones).
#
# The sources are private: run ./fetch-sources.sh first (see README.md), then ./make.sh or
#   docker build -t exploraal:dev --build-arg JOBS=16 .
# With podman/buildah add `--format docker`, otherwise the SHELL instruction (bash, pipefail) is ignored.
#
# The image contains private code: do not push it to public registries.

FROM almalinux:9.8

ARG JOBS=8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- system packages (translated from allsources/cicd/dependencies.debian) ----------------
RUN dnf -y install dnf-plugins-core epel-release \
	&& dnf config-manager --set-enabled crb \
	&& dnf -y install \
		gcc gcc-c++ gcc-gfortran make cmake git patch perl which wget curl-minimal \
		unzip tar bzip2 xz file diffutils findutils autoconf automake libtool bison flex \
		libX11-devel libXpm-devel libXft-devel libXext-devel libXmu-devel \
		mesa-libGL-devel mesa-libGLU-devel glew-devel freetype-devel \
		libpng-devel libjpeg-turbo-devel expat-devel openssl-devel zlib-devel \
		xz-devel bzip2-devel libxml2-devel libpq-devel \
		python3-devel python3-numpy eigen3-devel \
	&& dnf -y install \
		glibc-devel.i686 libstdc++-devel.i686 libgfortran.i686 libquadmath.i686 \
		libnsl.i686 libxcrypt-compat.i686 \
	&& dnf clean all
# (the i686 packages are for 3rdParty/CernZebraReader64, which builds a 32bit zebrareader
#  against shipped 32bit CERNLIB libraries that need libnsl.so.1 and libcrypt.so.1)

# --- allsources (ROOT, Geant4, Geant3, VMC, VGM, CLHEP, Pythia6, ...) -----------------------
# PROFILE selects the version set (profiles/<PROFILE>/): `production` (ROOT 6.24, Geant4 10.7,
# geant3 3.8, ...) or `latest`. profile.env pins the allsources/GenFit refs, allsources.sh adapts the
# vendored allsources checkout to AlmaLinux 9 (dead URLs, newer compilers, version bumps).
ARG PROFILE=production
ENV ALLSOURCES=/opt/CB/allsources
COPY vendor/allsources /src/allsources
COPY profiles/${PROFILE}/profile.env profiles/${PROFILE}/allsources.sh /src/profile/
RUN set -a && . /src/profile/profile.env && set +a \
	&& bash /src/profile/allsources.sh \
	&& mkdir -p ${ALLSOURCES} /tmp/allsources-build \
	&& cd /tmp/allsources-build \
	&& cmake -DCMAKE_INSTALL_PREFIX=${ALLSOURCES} /src/allsources \
	&& make -j${JOBS} \
	&& make install \
	&& cd / && rm -rf /tmp/allsources-build

# --- GenFit (not part of allsources; needed by 3rdParty/CBTTpcTracking) ---------------------
ARG GENFIT_REF
ENV GENFIT=/opt/genfit/lib \
	GENFIT_INCDIR=/opt/genfit/include
# (the sources stay in /src: GenFit's ROOT dictionaries reference the headers by their
#  build-time absolute paths, cling fails to autoload genfit classes without them)
RUN test -n "${GENFIT_REF}" \
	&& source ${ALLSOURCES}/thistr16.sh \
	&& curl -fsSL https://github.com/GenFit/GenFit/archive/refs/tags/${GENFIT_REF}.tar.gz | tar xz -C /src \
	&& cmake -S /src/GenFit-${GENFIT_REF} -B /tmp/genfit-build \
		-DCMAKE_INSTALL_PREFIX=/opt/genfit -DCMAKE_INSTALL_LIBDIR=lib \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=OFF \
	&& cmake --build /tmp/genfit-build -j${JOBS} \
	&& cmake --install /tmp/genfit-build \
	&& rm -rf /tmp/genfit-build \
	&& echo /opt/genfit/lib > /etc/ld.so.conf.d/genfit.conf && ldconfig

# --- explora + 3rdParty plugins -------------------------------------------------------------
# ROOT_INCLUDE_PATH: lets cling find the 3rdParty plugin headers when autoloading their classes
ENV EXPLORA_HOME=/opt/explora \
	ROOT_INCLUDE_PATH=/opt/explora/3rdParty/include
COPY profiles/${PROFILE}/explora.sh /src/profile/
COPY vendor/explora /src/TpcExplora
COPY vendor/plugins /src/plugins
COPY vendor/PLUGINS vendor/VERSIONS /src/
WORKDIR /src/TpcExplora
# Explora fixes for ROOT >= 6.26 (both also valid for ROOT 6.24, candidates for upstreaming):
#  - TGeo shape copy constructors were deleted: bind the returned const reference instead of
#    copying the TGeoBBox (behaviour unchanged)
#  - TRefArray::Init() only reallocates fUIDs if the size changes; CBTRefArray frees fUIDs before
#    assigning, so it must reset fSize too (otherwise: segfault in CBTVirtualMCStartPointStorage)
# The vendored private plugins are built as local plugins instead of letting cmake clone them.
# Without .git (e.g. a zip snapshot) gitinfo.h generation breaks: commit a local snapshot then.
RUN sed -i 's|^\(\s*\)TGeoBBox boundingBox = |\1const TGeoBBox \&boundingBox = |' \
		plugins/visualisation/CBTShowMagneticField.cpp vmc/base/CBTVirtualMCMagneticFieldMap.cpp \
	&& sed -i 's|^\(\s*\)fUIDs = NULL; *$|\1fUIDs = NULL; fSize = 0;|' dataobj/CBTRefArray.cpp \
	&& cp -a /src/plugins/. 3rdParty/ && rm -rf /src/plugins \
	&& bash /src/profile/explora.sh \
	&& : > 3rdParty/ExternalPlugins.txt \
	&& { echo; cat /src/PLUGINS; } >> 3rdParty/CustomPlugins.txt \
	&& if [ ! -d .git ]; then \
		git init -q && git add -A \
		&& git -c user.name=docker -c user.email=docker@localhost commit -qm "local snapshot"; \
	fi

RUN source ${ALLSOURCES}/thistr16.sh \
	&& mkdir -p ${EXPLORA_HOME} /build/explora \
	&& cd /build/explora \
	&& /src/TpcExplora/configure --enable-3rdparty --explora_home=${EXPLORA_HOME} \
	&& make -j${JOBS} \
	&& make install

# Freeze the environment of thistr16.sh + thisexplora.sh into a static file. Sourcing those scripts
# at runtime is fragile: thisroot.sh locates itself via BASH_ARGV, which is wrong whenever the
# calling script has arguments (e.g. the entrypoint with a multi-line `bash -c` command).
# (their output is discarded: thisexplora.sh warns when the ROOT version string differs in format)
RUN env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin \
		ALLSOURCES=${ALLSOURCES} EXPLORA_HOME=${EXPLORA_HOME} GENFIT=${GENFIT} GENFIT_INCDIR=${GENFIT_INCDIR} \
		ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH} \
		bash --noprofile --norc -c 'source ${ALLSOURCES}/thistr16.sh > /dev/null && source ${EXPLORA_HOME}/bin/thisexplora.sh > /dev/null && export -p' \
	| grep -vE '^declare -x (HOME|PWD|OLDPWD|SHLVL|_)=' > /etc/explora.env \
	&& grep -q '^declare -x ROOTSYS=' /etc/explora.env \
	&& echo 'source /etc/explora.env' > /etc/profile.d/explora.sh

COPY explora-env.sh /usr/local/bin/explora-env

# refs for traceability; make.sh fills them from vendor/VERSIONS (full list: /src/VERSIONS)
ARG EXPLORA_REF=unknown
ARG ALLSOURCES_REF=unknown
LABEL org.opencontainers.image.title="exploraal" \
	profile="${PROFILE}" \
	org.opencontainers.image.description="TpcExplora development image (AlmaLinux 9, allsources, GenFit)" \
	explora.ref="${EXPLORA_REF}" \
	allsources.ref="${ALLSOURCES_REF}" \
	genfit.ref="${GENFIT_REF}"

WORKDIR /build/explora
ENTRYPOINT ["/usr/local/bin/explora-env"]
CMD ["bash"]
