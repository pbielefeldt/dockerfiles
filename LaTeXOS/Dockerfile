FROM registry.opensuse.org/opensuse/leap:16.0.6.171@sha256:6a8998a33df6164d29d545c1bb8d9dd5a3595206d993b1a43c54de9aa33d8feb

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
