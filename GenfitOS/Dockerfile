# GenfitOS: GenFit2 track-fitting library on openSUSE Leap, with ROOT from the openSUSE science repo.
#
#   docker build --tag genfit:02-03-00 .
#
# GenFit's own test suite (ctest: streamerTest, unitTests, gtests) runs during the build.

FROM registry.opensuse.org/opensuse/leap:16.0

ARG GENFIT_REF=02-03-00
ARG JOBS=4

# ROOT 6 (root6-devel) from the openSUSE science repository, the rest from the default repos.
# The science repo path follows the Leap version of the base image (16.0 -> science/16.0).
# gcc13-c++: the root6 package was built with gcc 13, and its interpreter (cling) runs `g++-13`
# at startup to locate the C++ standard library headers, but root6 does not depend on it
# (Leap 16's default compiler is gcc 15). Without it, every ROOT start prints
# "ERROR in cling::CIFactory::createCI(): cannot extract standard library include paths!"
# (cling then falls back to its precompiled headers; simple macros still work).
RUN . /etc/os-release \
	&& zypper --non-interactive addrepo https://download.opensuse.org/repositories/science/${VERSION_ID}/science.repo \
	&& zypper --non-interactive --gpg-auto-import-keys refresh \
	&& zypper --non-interactive install \
		cmake make gcc-c++ gcc13-c++ curl tar gzip patch \
		root6-devel eigen3-devel gtest \
	&& zypper clean --all

# Build, test and install GenFit. The sources stay in the image: GenFit's ROOT dictionaries
# reference the headers by their absolute build-time path, cling cannot autoload genfit::
# classes without them.
# openSUSE's root6 is built without OpenGL, hence without Eve, but GenFit unconditionally builds
# its EventDisplay and links ROOT::Eve. genfit-no-eventdisplay.patch removes the EventDisplay
# (library sources, dictionary, the examples using it, unused Eve includes in two tests) and
# links ROOT::Geom, ROOT::EG and ROOT::Tree instead, which Eve used to pull in transitively.
# Track fitting itself and the ctest suite (streamerTest, unitTests, gtests) are unchanged.
# GENFIT/GENFIT_INCDIR: conventional variables used by GenFit-based projects to find the library.
# LD_LIBRARY_PATH/ROOT_INCLUDE_PATH: gSystem->Load("libgenfit2") only searches LD_LIBRARY_PATH (not
# the ldconfig cache), and cling needs the GenFit headers for interpreted code.
ENV GENFIT=/opt/genfit/lib \
	GENFIT_INCDIR=/opt/genfit/include \
	LD_LIBRARY_PATH=/opt/genfit/lib \
	ROOT_INCLUDE_PATH=/opt/genfit/include
COPY genfit-no-eventdisplay.patch /opt/genfit/
RUN mkdir -p /opt/genfit/src \
	&& curl -fsSL https://github.com/GenFit/GenFit/archive/refs/tags/${GENFIT_REF}.tar.gz \
		| tar xz --strip-components=1 -C /opt/genfit/src \
	&& patch -d /opt/genfit/src -p1 < /opt/genfit/genfit-no-eventdisplay.patch \
	&& cmake -S /opt/genfit/src -B /tmp/genfit-build \
		-DCMAKE_INSTALL_PREFIX=/opt/genfit -DCMAKE_INSTALL_LIBDIR=lib \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON \
	&& cmake --build /tmp/genfit-build -j${JOBS} \
	&& cmake --build /tmp/genfit-build -j${JOBS} --target tests \
	&& (cd /tmp/genfit-build && ctest --output-on-failure) \
	&& cmake --install /tmp/genfit-build \
	&& rm -rf /tmp/genfit-build \
	&& echo /opt/genfit/lib > /etc/ld.so.conf.d/genfit.conf && ldconfig

# (overrides the OCI labels inherited from the openSUSE base image, which would otherwise
#  present this image as an openSUSE product with the base image's version and date)
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="genfit" \
	org.opencontainers.image.description="GenFit2 on openSUSE Leap 16.0 with ROOT 6 (science repo)" \
	org.opencontainers.image.version="${GENFIT_REF}" \
	org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.vendor="Philipp Bielefeldt" \
	org.opencontainers.image.url="https://github.com/pbielefeldt/dockerfiles/tree/main/GenfitOS" \
	org.opencontainers.image.source="https://github.com/pbielefeldt/dockerfiles" \
	org.opencontainers.image.documentation="https://github.com/pbielefeldt/dockerfiles/blob/main/GenfitOS/README.md" \
	org.opencontainers.image.licenses="LGPL-3.0-only" \
	genfit.ref="${GENFIT_REF}"

WORKDIR /work
CMD ["bash"]
