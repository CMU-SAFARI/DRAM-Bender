program_NAME := smc_parser
program_CXX_SRCS := lex.yy.c y.tab.c $(wildcard ../*.c*)
program_CXX_OBJS := ${program_CXX_SRCS:.cpp=.o}
program_OBJS := $(program_CXX_OBJS)
program_INCLUDE_DIRS := ../ ../../../boost-lib
program_LIBRARY_DIRS :=
program_LIBRARIES := 
CPPFLAGS += -g -std=c++11 -pthread

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir))
LDFLAGS += $(foreach librarydir,$(program_LIBRARY_DIRS),-L$(librarydir))
LDFLAGS += $(foreach library,$(program_LIBRARIES),-l$(library))

CC=g++

.PHONY: all clean distclean

all: $(program_NAME)

$(program_NAME): $(program_OBJS) lex.yy.c
	$(CC) $(CPPFLAGS) $(program_OBJS) -o $(program_NAME) $(LDFLAGS)

lex.yy.c: y.tab.c smc.l
	flex smc.l

y.tab.c: smc.y
	yacc -d smc.y

distclean: clean
