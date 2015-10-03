# Name of your emacs binary
EMACS = emacs

BATCH = $(EMACS) --batch --no-init-file					\
	--eval "(require 'org)"						\
	--eval "(org-babel-do-load-languages 'org-babel-load-languages  \
		'((shell . t)))"					\
	--eval "(setq org-babel-use-quick-and-dirty-noweb-expansion t)" \
        --eval "(setq org-confirm-babel-evaluate nil)"

GIT_BRANCH = $(shell git branch | grep \* | cut -d' ' -f2)

CCAGE_DIRECTORY	    = /sps/nemo/scratch/garrido/workdir/supernemo/simulations/snemo_simulation_configuration
LAL_DIRECTORY	    = /exp/nemo/garrido/workdir/supernemo/simulations/snemo_simulation_configuration
XTREMWEB_DIRECTORY  = /home/vmuser/snemo_simulation_configuration

FILES        = $(notdir $(shell ls *.org 2> /dev/null | sed -e 's/snvariant_manager.org//g'))
ORG_FILES    = $(FILES) snvariant_manager.org
TANGLE_FILES = $(ORG_FILES:%.org=$(GIT_BRANCH)/.%.tangle)

all: org

org: $(TANGLE_FILES)
	@if ls | grep -q "\.def"; then mv *.def $(GIT_BRANCH)/.;fi
	@if ls | grep -q "\.conf"; then mv *.conf $(GIT_BRANCH)/.;fi
	@if ls | grep -q "\.lis"; then mv *.lis $(GIT_BRANCH)/.;fi
	@find $(GIT_BRANCH) -type f -print0 | xargs -0 sed -i 's#@SNEMO_SIMULATION_CONFIGURATION@#'`pwd`/$(GIT_BRANCH)'#g'
	@if [ -L current ]; then rm current;fi && ln -sf $(GIT_BRANCH) current

$(GIT_BRANCH)/.%.tangle: %.org
	@echo "NOTICE: Tangling $< file"
	@$(BATCH) --visit "$<" --funcall org-babel-tangle > /dev/null 2>&1
	@mkdir -p $(GIT_BRANCH)
	@touch $@

tarball: org
	@echo "NOTICE: Making tarball configuration"
	@tar -czf $(GIT_BRANCH).tar.gz --exclude='.*.tangle' $(GIT_BRANCH)

push: lyon lal xtremweb

lyon: org
	@echo "NOTICE: Pushing current configuration to Lyon"
	@mkdir -p /tmp/ssc.d/ && rm -rf /tmp/ssc.d/* && cp -r $(GIT_BRANCH)/*.{conf,def,lis} /tmp/ssc.d/. && sed -i -e 's#'`pwd`/$(GIT_BRANCH)'#$(CCAGE_DIRECTORY)/$(GIT_BRANCH)#g' /tmp/ssc.d/*
	@ssh garrido@ccage.in2p3.fr "mkdir -p $(CCAGE_DIRECTORY)/$(GIT_BRANCH); cd $(CCAGE_DIRECTORY); if [ -L current ]; then rm current; fi; ln -sf $(GIT_BRANCH) current"
	@scp /tmp/ssc.d/*.{conf,def,lis} garrido@ccage.in2p3.fr:$(CCAGE_DIRECTORY)/$(GIT_BRANCH)/.

lal: org
	@echo "NOTICE: Pushing current configuration to LAL"
	@mkdir -p /tmp/ssc.d/ && rm -rf /tmp/ssc.d/* && cp -r $(GIT_BRANCH)/*.{conf,def,lis} /tmp/ssc.d/. && sed -i -e 's#'`pwd`/$(GIT_BRANCH)'#$(LAL_DIRECTORY)/$(GIT_BRANCH)#g' /tmp/ssc.d/*
	@ssh garrido@lx3.lal.in2p3.fr "mkdir -p $(LAL_DIRECTORY)/$(GIT_BRANCH); cd $(LAL_DIRECTORY); test -L current && rm current; ln -sf $(GIT_BRANCH) current"
	@scp /tmp/ssc.d/*.{conf,def,lis} garrido@lx3.lal.in2p3.fr:$(LAL_DIRECTORY)/$(GIT_BRANCH)/.

xtremweb: org
	@echo "NOTICE: Pushing current configuration to XtremWeb"
	@mkdir -p /tmp/ssc.d/ && rm -rf /tmp/ssc.d/* && cp -r $(GIT_BRANCH)/*.{conf,def,lis} /tmp/ssc.d/. && sed -i -e 's#'`pwd`/$(GIT_BRANCH)'#$(XTREMWEB_DIRECTORY)/$(GIT_BRANCH)#g' /tmp/ssc.d/*
	@ssh -p 2222 vmuser@134.158.89.155 "mkdir -p $(XTREMWEB_DIRECTORY)/$(GIT_BRANCH); cd $(XTREMWEB_DIRECTORY); test -L current && rm current; ln -sf $(GIT_BRANCH) current"
	@scp -P 2222 /tmp/ssc.d/*.{conf,def,lis} vmuser@134.158.89.155:$(XTREMWEB_DIRECTORY)/$(GIT_BRANCH)/.

clean:
	@rm -f *.tangle *.tar.gz *.conf *.def *.aux *.tex *.fls *fdb_latexmk *.log *.pdf *~ *.el
	@rm -f *.auxlock *.out *.toc *.sty
	@rm -rf doc current latex.d $(GIT_BRANCH)
