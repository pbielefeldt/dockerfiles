FROM registry.opensuse.org/opensuse/leap:15.5

RUN zypper --non-interactive clean --all

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/15.5/Publishing:TeXLive.repo
RUN find /etc/zypp/repos.d/ -name '*.repo' -exec sed -i 's/http:\/\/download/https\:\/\/download/' {} \;
RUN zypper --gpg-auto-import-keys refresh
RUN zypper --non-interactive update --no-confirm

RUN zypper modifyrepo -p 70 Publishing_TeXLive

RUN zypper install -y make

COPY all_latex.sh ./
RUN sh -e all_latex.sh

RUN /usr/share/texmf/texconfig/update
RUN fc-cache -fsv
