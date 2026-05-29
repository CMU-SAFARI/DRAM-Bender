program_NAME := pySoftMC
program_CXX_SRCS := $(wildcard ../*.c) $(wildcard ../*.cpp) ./pySoftMC.cpp
program_CXX_OBJS := ${program_CXX_SRCS:.cpp=.o}
program_CXX_OBJS := ${program_CXX_OBJS:.c=.o}
program_OBJS := $(program_CXX_OBJS)

PYTHON_INCLUDES  ?= $(shell python3-config --includes)
PYTHON_LDFLAGS   ?= $(shell python3-config --ldflags --embed 2>/dev/null || python3-config --ldflags)
PYTHON_EXT_SUFFIX ?= $(PYTHON_EXT_SUFFIX)
program_INCLUDE_DIRS := . .. ../ext/pybind11/include
CPPFLAGS += -g -std=c++14 -pthread -O3 -fPIC -Wall

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir)) $(PYTHON_INCLUDES) -DPYSMC
LDFLAGS  += $(PYTHON_LDFLAGS)

SHARED_LIB_FLAGS := -shared -fPIC 

CC=g++

.PHONY: all clean distclean

all: $(program_NAME)
	@- $(RM) $(program_OBJS)

$(program_NAME): $(program_OBJS)
	$(CC) $(CPPFLAGS) ${SHARED_LIB_FLAGS} $(program_OBJS) -o $(program_NAME)$(PYTHON_EXT_SUFFIX) $(LDFLAGS)

clean:
	@- $(RM) $(program_NAME)$(PYTHON_EXT_SUFFIX)
	@- $(RM) $(program_OBJS)

distclean: clean
