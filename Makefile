# Name of your emacs binary
EMACS = emacs

BATCH = $(EMACS) --batch -Q --eval '(require (quote org))'			\
	--eval '(org-babel-do-load-languages (quote org-babel-load-languages)   \
		(quote((sh . t))))'						\
	--eval '(setq org-confirm-babel-evaluate nil)'

GIT_BRANCH = $(shell git branch | grep \* | cut -d' ' -f2)
CCAGE_DIRECTORY = /sps/nemo/scratch/garrido/simulations/configuration

FILES  = $(notdir $(shell ls *.org 2> /dev/null | sed -e "s@simulation_publish.org@@g"))
FILEST = $(FILES:%.org=$(GIT_BRANCH)/.%.tangle)

all: org

org: $(FILEST)
	@if ls | grep -q "\.def"; then mv *.def $(GIT_BRANCH)/.;fi
	@if ls | grep -q "\.conf"; then mv *.conf $(GIT_BRANCH)/.;fi
	@if [ -L current ]; then rm current;fi && ln -sf $(GIT_BRANCH) current

$(GIT_BRANCH)/.%.tangle: %.org
	@echo "Tangling $< file"
	@$(BATCH) --eval '(org-babel-tangle-file "$<")'
	@mkdir -p $(GIT_BRANCH)
	@touch $@

tarball: org
	@echo "Making tarball configuration"
	@tar czf $(GIT_BRANCH).tar.gz $(GIT_BRANCH)

push: org
	@echo "Pushing current configuration to Lyon"
	@ssh garrido@ccage.in2p3.fr "cd $(CCAGE_DIRECTORY) && mkdir -p $(GIT_BRANCH); if [ -L current ]; then rm current; fi; ln -sf $(GIT_BRANCH) current"
	@rsync -e ssh -avP --delete --recursive --force $(GIT_BRANCH)/*.{conf,def} garrido@ccage.in2p3.fr:$(CCAGE_DIRECTORY)/$(GIT_BRANCH)/.

doc: doc/index.html

doc/index.html:
	mkdir -p doc/stylesheets
	$(BATCH) --batch -Q --eval '(org-babel-tangle-file "simulation_publish.org")'
	$(BATCH) --batch -Q --eval '(org-babel-load-file "simulation_publish.org")'
	rm simulation_publish.el
	echo "Documentation published to doc/"

clean:
	rm -f *.tangle *.tar.gz *.conf *.def *.aux *.tex *.fls *fdb_latexmk *.log *.pdf doc/*html *~
	rm -rf doc current $(GIT_BRANCH)
