FROM registry.opensuse.org/opensuse/leap:15.5

RUN zypper --non-interactive clean --all

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/15.5/Publishing:TeXLive.repo
RUN find /etc/zypp/repos.d/ -name '*.repo' -exec sed -i 's/http:\/\/download/https\:\/\/download/' {} \;
RUN zypper --gpg-auto-import-keys refresh
RUN zypper --non-interactive update --no-confirm

RUN zypper modifyrepo -p 70 Publishing_TeXLive

RUN zypper install --no-confirm make
RUN zypper --non-interactive install --force-resolution --no-confirm texlive-scheme-full
RUN zypper install --no-confirm 'tex(beamer.cls)'
RUN zypper install --no-confirm 'tex(pzdr.tfm)'
RUN zypper install --no-confirm 'tex(fancyvrb.sty)'
RUN zypper install --no-confirm 'tex(framed.sty)'


# COPY all_latex.sh ./
# RUN sh -e all_latex.sh

RUN /usr/share/texmf/texconfig/update
RUN fc-cache -fsv
