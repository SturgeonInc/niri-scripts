#!/usr/bin/env -S make --file

SCRIPTS := $(abspath $(wildcard *.sh))
SCRIPT_FOLDER := $(HOME)/.local/bin/

LN_OPTS := --verbose --symbolic --force

all: *.sh
	ln $(LN_OPTS) --target-directory=$(SCRIPT_FOLDER) $(SCRIPTS)

%: %.sh
	ln $(LN_OPTS) --target-directory=$(SCRIPT_FOLDER) $(abspath $@.sh)

help:
	$(info Link the following:  )
	$(info ================     )
	$(info $(SCRIPTS)           )
	$(info ===============      )
	$(info To $(SCRIPT_FOLDER)  )
	$(info With "ln $(LN_OPTS)" )
