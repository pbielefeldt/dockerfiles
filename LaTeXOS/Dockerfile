FROM registry.opensuse.org/opensuse/leap:16.0.6.463@sha256:9c88da273b41600dfd12790849dfb198ddefed3a109eaf42ada944afb4282a9d

RUN zypper --non-interactive clean --all

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/16.0/Publishing:TeXLive.repo
RUN zypper --gpg-auto-import-keys refresh
RUN zypper modifyrepo -p 70 Publishing_TeXLive

RUN zypper --non-interactive update --no-confirm

COPY all_latex.sh ./
RUN sh -e all_latex.sh

# needed for some compilation (e.g. PIThesis)
RUN zypper install --no-confirm make

RUN /usr/share/texmf/texconfig/update
RUN fc-cache -fsv
