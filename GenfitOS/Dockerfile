FROM registry.opensuse.org/opensuse/leap:15.4

WORKDIR /home/genfit/

# add Science repo
RUN zypper --non-interactive addrepo https://download.opensuse.org/repositories/science/15.4/science.repo
RUN zypper --non-interactive --gpg-auto-import-keys refresh -s
RUN zypper update -y

# dependencies from default repo
RUN zypper --non-interactive install cmake make gcc-c++
RUN zypper --non-interactive install pkg-config
RUN zypper --non-interactive install git
RUN zypper --non-interactive install gtest

# CERN ROOT
RUN zypper --non-interactive install eigen3-devel
RUN zypper --non-interactive install clhep
RUN zypper --non-interactive install root6

# build Genfit
RUN mkdir build && mkdir install
RUN git clone https://github.com/GenFit/GenFit.git src

RUN cd build && cmake ../src -DCMAKE_INSTALL_PREFIX=../install/ && make && make install

