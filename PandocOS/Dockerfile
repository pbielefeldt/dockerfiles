FROM registry.opensuse.org/opensuse/leap:16.0.6.146@sha256:4fdcd6445a8e85ed93da39089fba512d6da3a96dbe0f0fadf1a093a69854a796

RUN zypper --non-interactive clean --all

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/16.0/Publishing:TeXLive.repo
RUN zypper --gpg-auto-import-keys refresh
RUN zypper --non-interactive update --no-confirm
RUN zypper modifyrepo -p 70 Publishing_TeXLive

RUN zypper install --no-confirm curl
RUN zypper --non-interactive install --force-resolution --no-confirm texlive-scheme-basic texlive-xetex liberation-fonts texlive-lm-math pandoc
RUN zypper install --no-confirm 'tex(beamer.cls)' 'tex(pzdr.tfm)' 'tex(fancyvrb.sty)' 'tex(framed.sty)'

RUN /usr/share/texmf/texconfig/update
RUN fc-cache -fsv

RUN curl https://codeberg.org/pbiel/LaTeX-Stuff/raw/branch/master/markdown2pdf.sh > markdown2pdf.sh
RUN chmod +x markdown2pdf.sh
RUN curl https://codeberg.org/pbiel/LaTeX-Stuff/raw/branch/master/markdown2docx.sh > markdown2docx-experimental.sh
RUN chmod +x markdown2docx-experimental.sh
