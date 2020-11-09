# Makefile used to build Webots files
EXTRA_OBJ=lua_webots.o
LIBNAME=webots
EXTRA_CLEAN=lua_webots.c
include ../../Makefile.inc

lua_webots.c: lua_webots.i
	$(V)printf "\t%b %b\n" $(CCCOLOR)SWIG$(ENDCOLOR) $(SRCCOLOR)$@$(ENDCOLOR);
	$(V)swig -lua -o $@ -I$(WEBOTS_HOME)/include/controller/c $^

WEBOTS_HOME=/usr/local/webots
INCLUDES+=-I$(WEBOTS_HOME)/include/controller/c
CFLAGS+= -std=c99
LDFLAGS+=-L$(WEBOTS_HOME)/lib/controller -lController
