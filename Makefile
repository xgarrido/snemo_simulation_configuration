# Name of your emacs binary
EMACS = emacs

BATCH = $(EMACS) --batch -Q --eval '(require (quote org))'			\
	--eval '(org-babel-do-load-languages (quote org-babel-load-languages)   \
		(quote((sh . t))))'						\
	--eval '(setq org-confirm-babel-evaluate nil)'

FILES = $(wildcard *.org)

GIT_BRANCH = `git branch | grep \* | cut -d' ' -f2`
CCAGE_DIRECTORY = /sps/nemo/scratch/garrido/simulations/configuration
all: org

org: $(FILES:.org=.tangle)
pdf: $(FILES:.org=.pdf)
html: $(FILES:.org=.html)

%.tangle: %.org
	@echo "Tangling $< file"
	@$(BATCH) --eval '(org-babel-tangle-file "$<")'
	@mkdir -p $(GIT_BRANCH)
	@mv *.conf $(GIT_BRANCH)/.
	@touch $@

%.tex: %.org
	$(BATCH) $*.org -f org-export-as-latex

%.pdf: %.org
	$(BATCH) $*.org -f org-export-as-pdf

%.html: %.org
	$(BATCH) $*.org -f org-export-as-html

tarball: org
	@echo "Making tarball configuration"
	tar czf configuration.tar.gz *.conf

push: org
	@echo "Pushing current configuration to Lyon"
	ssh garrido@ccage.in2p3.fr mkdir -p $(CCAGE_DIRECTORY)/$(GIT_BRANCH)
	rsync --recursive -e ssh -avP $(GIT_BRANCH)/*.conf garrido@ccage.in2p3.fr:$(CCAGE_DIRECTORY)/$(GIT_BRANCH)/.

doc: doc/index.html

doc/index.html:
	mkdir -p doc
	$(EMACS) --batch -Q --eval '(org-babel-load-file "starter-kit-publish.org")'
	rm starter-kit-publish.el
	cp doc/starter-kit.html doc/index.html
	echo "Documentation published to doc/"

clean:
	rm -f *.tangle *.tar.gz *.conf *.aux *.tex *.fls *fdb_latexmk *.log *.pdf doc/*html *~
	rm -rf doc
