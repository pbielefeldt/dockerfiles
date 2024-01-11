FROM registry.opensuse.org/opensuse/leap:15.5

RUN zypper addrepo https://download.opensuse.org/repositories/Publishing:TeXLive/15.5/Publishing:TeXLive.repo
RUN find /etc/zypp/repos.d/ -name '*.repo' -exec sed -i 's/http:\/\/download/https\:\/\/download/' {} \;
RUN zypper --gpg-auto-import-keys refresh

#RUN zypper install -y make
RUN zypper install -y curl

RUN zypper install -y texlive-scheme-basic
RUN zypper install -y texlive-xetex
RUN zypper install -y liberation-fonts
RUN zypper install -y texlive-lm-math

RUN zypper install -y pandoc

RUN zypper install -y 'tex(beamer.cls)'
RUN zypper install -y 'tex(pzdr.tfm)'
RUN zypper install -y 'tex(fancyvrb.sty)'
RUN zypper install -y 'tex(framed.sty)'
#RUN /sbin/mkinitrd
#RUN fmtutil-sys --missing
RUN fc-cache -fsv

RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2pdf.sh > markdown2pdf.sh
RUN chmod +x markdown2pdf.sh
RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2docx.sh > markdown2docx-experimental.sh
RUN chmod +x markdown2docx-experimental.sh

