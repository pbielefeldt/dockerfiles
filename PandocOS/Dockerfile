FROM registry.opensuse.org/opensuse/leap:15.4

RUN zypper ref -s
RUN zypper update -y

#RUN zypper install -y make
RUN zypper install -y curl

RUN zypper install -y texlive-scheme-basic texlive-xetex
RUN zypper install -y liberation-fonts texlive-lm-math
RUN zypper install -y pandoc

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

