#!/usr/bin/env -S make --file

SCRIPTS := $(abspath $(wildcard *.sh))
INSTALLATION_FOLDER := $(HOME)/.local/bin/

LN_OPTS := --verbose --symbolic --force

.PHONY: install
install:
	ln $(LN_OPTS) --target-directory=$(INSTALLATION_FOLDER) $(SCRIPTS)

.PHONY: install-%
install-%: %.sh
	ln $(LN_OPTS) --target-directory=$(INSTALLATION_FOLDER) $(abspath $@.sh)

.PHONY: help
help:
	$(info Link the following:  )
	$(info ================     )
	$(info $(SCRIPTS)           )
	$(info ===============      )
	$(info To $(INSTALLATION_FOLDER)  )
	$(info With "ln $(LN_OPTS)" )
