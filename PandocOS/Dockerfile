FROM pbielefeldt/latexos:15.6.2

RUN zypper --non-interactive clean --all

RUN zypper install -y curl
RUN zypper install -y pandoc

RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2pdf.sh > markdown2pdf.sh
RUN chmod +x markdown2pdf.sh
RUN curl https://raw.githubusercontent.com/pbielefeldt/LaTeX-Stuff/master/markdown2docx.sh > markdown2docx-experimental.sh
RUN chmod +x markdown2docx-experimental.sh
