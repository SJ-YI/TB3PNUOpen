# Master Makefile to compile all Lua/C++ libraries
CWD= $(shell pwd)
PWD= $(subst /,\/,$(CWD)/Player/Lib)
.PHONY: all none clean modules controllers

all none: modules controllers

%:

controllers:
	@for dir in `ls Webots/controllers`; do \
	printf "  %b \n" $$dir ; \
	$(MAKE) -C Webots/controllers/$$dir clean; \
	$(MAKE) -C Webots/controllers/$$dir; \
	done

modules:
	@for dir in `ls Modules`; do \
	printf "  %b \n" $$dir ; \
	$(MAKE) -C Modules/$$dir clean; \
	$(MAKE) -C Modules/$$dir; \
	done

clean:
	@for dir in `ls Modules`; do \
	printf "  %b \n" $$dir ; \
	$(MAKE) -C Modules/$$dir clean; \
	done
	@for dir in `ls Webots/controllers`; do \
	printf "  %b \n" $$dir ; \
	$(MAKE) -C Webots/controllers/$$dir clean; \
	done
