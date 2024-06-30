# Makefile for building a LaTeX document with bibliography using biber

# The main .tex file
MAIN = main

# The latex and biber commands
LATEX = pdflatex
BIBER = biber

# The final output PDF
OUTPUT = $(MAIN).pdf

# Temporary files to clean up
TEMP_FILES = $(MAIN).aux $(MAIN).bbl $(MAIN).bcf $(MAIN).blg $(MAIN).log $(MAIN).out $(MAIN).run.xml

# Default target: build the PDF
all: $(OUTPUT)

# Rule to build the PDF
$(OUTPUT): $(MAIN).tex references.bib
	$(LATEX) $(MAIN).tex
	$(BIBER) $(MAIN)
	$(LATEX) $(MAIN).tex
	$(LATEX) $(MAIN).tex

# Clean up temporary files
clean:
	rm -f $(TEMP_FILES)

# Clean up everything, including the final PDF
cleanall: clean
	rm -f $(OUTPUT)

.PHONY: all clean cleanall
