#!/usr/bin/env -S make --file

SCRIPTS := $(abspath $(wildcard *.sh))
SCRIPT_FOLDER := $(HOME)/.local/bin/

LN_OPTS := --verbose --symbolic --force

t:
	realpath *.sh

all: *.sh
	ln $(LN_OPTS) --target-directory=$(SCRIPT_FOLDER) $(SCRIPTS)

%: %.sh
	ln $(LN_OPTS) --target-directory=$(SCRIPT_FOLDER) $(abspath $@.sh)
