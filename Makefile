# Name of your emacs binary
EMACS=emacs

BATCH=$(EMACS) --batch -Q --eval '(require (quote org))'			\
	--eval '(org-babel-do-load-languages (quote org-babel-load-languages)   \
		(quote((sh . t) (python . t))))'				\
	--eval '(setq org-confirm-babel-evaluate nil)'

FILES = $(wildcard *.org)

all: org

org: simulation_config.org
	$(BATCH) --eval '(org-babel-tangle-file "$<")'

#$(BATCH) --eval '(mapc (lambda (x) (org-babel-tangle-file (symbol-name x))) (quote ($(FILES))))'

doc: doc/index.html

doc/index.html:
	mkdir -p doc
	$(EMACS) --batch -Q --eval '(org-babel-load-file "starter-kit-publish.org")'
	rm starter-kit-publish.el
	cp doc/starter-kit.html doc/index.html
	echo "Documentation published to doc/"

clean:
	rm -f *.conf *.aux *.tex *.fls *fdb_latexmk *.pdf doc/*html *~
	rm -rf doc
