# Name of your emacs binary
EMACS = emacs

BATCH = $(EMACS) --batch --no-init-file					\
	--eval "(require 'org)"						\
	--eval "(org-babel-do-load-languages 'org-babel-load-languages  \
		'((sh . t)))"						\
	--eval "(setq org-confirm-babel-evaluate nil)"

GIT_BRANCH = $(shell git branch | grep \* | cut -d' ' -f2)

CCAGE_DIRECTORY = /sps/nemo/scratch/garrido/simulations/configuration
LAL_DIRECTORY	= /exp/nemo/garrido/workdir/supernemo/simulations/configuration

FILES  = $(notdir $(shell ls *.org 2> /dev/null | sed -e "s@simulation_publish.org@@g"))
FILEST = $(FILES:%.org=$(GIT_BRANCH)/.%.tangle)

all: org

org: $(FILEST)
	@if ls | grep -q "\.def"; then mv *.def $(GIT_BRANCH)/.;fi
	@if ls | grep -q "\.conf"; then mv *.conf $(GIT_BRANCH)/.;fi
	@if [ -L current ]; then rm current;fi && ln -sf $(GIT_BRANCH) current

$(GIT_BRANCH)/.%.tangle: %.org
	@echo "NOTICE: Tangling $< file"
	@$(BATCH) --eval '(org-babel-tangle-file "$<")'
	@mkdir -p $(GIT_BRANCH)
	@touch $@

tarball: org
	@echo "NOTICE: Making tarball configuration"
	@tar czf $(GIT_BRANCH).tar.gz $(GIT_BRANCH)

push: org
	@echo "NOTICE: Pushing current configuration to Lyon"
	@ssh garrido@ccage.in2p3.fr "cd $(CCAGE_DIRECTORY) && mkdir -p $(GIT_BRANCH); if [ -L current ]; then rm current; fi; ln -sf $(GIT_BRANCH) current"
	@rsync -e ssh -avP --delete --recursive --force $(GIT_BRANCH)/*.{conf,def} garrido@ccage.in2p3.fr:$(CCAGE_DIRECTORY)/$(GIT_BRANCH)/.
	@echo "NOTICE: Pushing current configuration to LAL"
	@ssh garrido@lx3.lal.in2p3.fr "cd $(LAL_DIRECTORY) && mkdir -p $(GIT_BRANCH); if ( -d current ) then; rm current; endif; ln -sf $(GIT_BRANCH) current"
	@rsync -e ssh -avP --delete --recursive --force $(GIT_BRANCH)/*.{conf,def} garrido@lx3.lal.in2p3.fr:$(LAL_DIRECTORY)/$(GIT_BRANCH)/.

doc: $(FILES) simulation_publish.org
	@mkdir -p doc/html/css
	$(BATCH) --eval '(org-babel-tangle-file "simulation_publish.org")'
	$(BATCH) --eval '(org-babel-load-file   "simulation_publish.org")'
	rm simulation_publish.el
	echo "NOTICE: Documentation published to doc/"

clean:
	@rm -f *.tangle *.tar.gz *.conf *.def *.aux *.tex *.fls *fdb_latexmk *.log *.pdf *~
	@rm -f *.auxlock *.out
	@rm -rf doc current latex.d $(GIT_BRANCH)
