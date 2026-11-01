FROM registry.opensuse.org/opensuse/leap:16.0.6.461@sha256:a9273058652f1f7d39f7c8439079662bd387be74013c6b40c9dfc42b228a972c

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
