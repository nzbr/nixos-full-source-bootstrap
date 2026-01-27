.PHONY: all
all: thesis.pdf thesis.txt thesis.md thesis.docx

watch:
	while true; do inotifywait -r -e modify src; $(MAKE) all; done

PREREQUISISTES := src/thesis.typ src/thesis.bib $(shell find src -name '*.typ') generated/nix-extension-fixed.svg generated/bootstrap-tools-fixed.svg

thesis.docx: thesis.html
	pandoc -f html -t docx -o thesis.docx thesis.html

thesis.md: thesis.html
	pandoc -f html -t markdown_strict --wrap=none -o thesis.md thesis.html

thesis.txt: thesis.html
	pandoc -f html -t plain --wrap=none -o thesis.txt thesis.html

thesis.html: $(PREREQUISISTES)
	typst compile --features html --format html --input html=true --root . --ignore-system-fonts --font-path generated/fonts $< $@

thesis.pdf: $(PREREQUISISTES)
	typst compile --format pdf --root . --ignore-system-fonts --font-path generated/fonts $< $@

generated/%-fixed.svg: generated/%.svg
	sed 's|font-family="monospace"|font-family="Copperflame Mono"|g' $< > $@

generated/%.svg: assets/%.uxf
	xvfb-run umlet -action=convert -format=svg -filename=$(PWD)/$< -output=$(PWD)/generated
