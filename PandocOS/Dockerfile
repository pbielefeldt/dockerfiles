FROM registry.opensuse.org/opensuse/leap:15.6

RUN zypper --non-interactive clean --all

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/15.6/Publishing:TeXLive.repo
RUN find /etc/zypp/repos.d/ -name '*.repo' -exec sed -i 's/http:\/\/download/https\:\/\/download/' {} \;
RUN zypper --gpg-auto-import-keys refresh
RUN zypper --non-interactive update --no-confirm

RUN zypper modifyrepo -p 70 Publishing_TeXLive

RUN zypper install --no-confirm curl

RUN zypper --non-interactive install --force-resolution --no-confirm texlive-scheme-basic texlive-xetex liberation-fonts texlive-lm-math pandoc

RUN zypper install --no-confirm 'tex(beamer.cls)' 'tex(pzdr.tfm)' 'tex(fancyvrb.sty)' 'tex(framed.sty)'

RUN /usr/share/texmf/texconfig/update
RUN fc-cache -fsv

RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2pdf.sh > markdown2pdf.sh
RUN chmod +x markdown2pdf.sh
RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2docx.sh > markdown2docx-experimental.sh
RUN chmod +x markdown2docx-experimental.sh
