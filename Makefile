# Name of your emacs binary
EMACS = emacs

BATCH = $(EMACS) --batch -Q --eval '(require (quote org))'			\
	--eval '(org-babel-do-load-languages (quote org-babel-load-languages)   \
		(quote((sh . t))))'						\
	--eval '(setq org-confirm-babel-evaluate nil)'

GIT_BRANCH = $(shell git branch | grep \* | cut -d' ' -f2)
CCAGE_DIRECTORY = /sps/nemo/scratch/garrido/simulations/configuration

FILES  = $(notdir $(shell ls *.org 2> /dev/null))
FILESO = $(FILES:%.org=$(GIT_BRANCH)/.%.tangle)

all: org

org: $(FILESO)

$(GIT_BRANCH)/.%.tangle: %.org
	@echo "Tangling $< file"
	@$(BATCH) --eval '(org-babel-tangle-file "$<")'
	@mkdir -p $(GIT_BRANCH)
	@mv *.conf $(GIT_BRANCH)/.
	@if [ -L current ]; then rm current;fi && ln -sf $(GIT_BRANCH) current
	@touch $@

tarball: org
	@echo "Making tarball configuration"
	@tar czf $(GIT_BRANCH).tar.gz $(GIT_BRANCH)

push: org
	@echo "Pushing current configuration to Lyon"
	@ssh garrido@ccage.in2p3.fr "cd $(CCAGE_DIRECTORY) && mkdir -p $(GIT_BRANCH); if [ -L current ]; then rm current; fi; ln -sf $(GIT_BRANCH) current"
	@rsync --recursive -e ssh -avP $(GIT_BRANCH)/*.conf garrido@ccage.in2p3.fr:$(CCAGE_DIRECTORY)/$(GIT_BRANCH)/.

doc: doc/index.html

doc/index.html:
	mkdir -p doc
	$(EMACS) --batch -Q --eval '(org-babel-load-file "starter-kit-publish.org")'
	rm starter-kit-publish.el
	cp doc/starter-kit.html doc/index.html
	echo "Documentation published to doc/"

clean:
	rm -f *.tangle *.tar.gz *.conf *.aux *.tex *.fls *fdb_latexmk *.log *.pdf doc/*html *~
	rm -rf doc current $(GIT_BRANCH)
