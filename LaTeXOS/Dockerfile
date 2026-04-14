FROM registry.opensuse.org/opensuse/leap:16.0.5.1@sha256:c0dc066b896836b4c9ae4574df5abad6026965beeef943ef098fb59e6d6358ea

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
