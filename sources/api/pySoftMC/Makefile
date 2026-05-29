program_NAME := pySoftMC
program_CXX_SRCS := $(wildcard ../*.c) $(wildcard ../*.cpp) ./pySoftMC.cpp
program_CXX_OBJS := ${program_CXX_SRCS:.cpp=.o}
program_CXX_OBJS := ${program_CXX_OBJS:.c=.o}
program_OBJS := $(program_CXX_OBJS)

python_INCLUDE_FLAGS := $(shell python3-config --includes)
program_INCLUDE_DIRS := . .. ../ext/pybind11/include
program_LIBRARY_DIRS :=
program_LIBRARIES :=
CPPFLAGS += -g -std=c++14 -pthread -O3 -fPIC -Wall

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir)) $(python_INCLUDE_FLAGS) -DPYSMC
LDFLAGS += $(foreach librarydir,$(program_LIBRARY_DIRS),-L$(librarydir))
LDFLAGS += $(foreach library,$(program_LIBRARIES),-l$(library))
LDFLAGS += $(shell python3-config --ldflags --embed 2>/dev/null || python3-config --ldflags)

SHARED_LIB_FLAGS := -shared -fPIC 

CC=g++

.PHONY: all clean distclean

all: $(program_NAME)
	@- $(RM) $(program_OBJS)

$(program_NAME): $(program_OBJS)
	$(CC) $(CPPFLAGS) ${SHARED_LIB_FLAGS} $(program_OBJS) -o $(program_NAME)$(shell python3-config --extension-suffix) $(LDFLAGS)

clean:
	@- $(RM) $(program_NAME)$(shell python3-config --extension-suffix)
	@- $(RM) $(program_OBJS)

distclean: clean
