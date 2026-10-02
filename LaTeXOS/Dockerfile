FROM registry.opensuse.org/opensuse/leap:16.0.6.374@sha256:5bc9e1242fc2c92dbbcaf4db5e2eadad062c4c0434550c53822201f18799d55a

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
