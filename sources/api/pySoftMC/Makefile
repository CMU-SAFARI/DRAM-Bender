# https://stackoverflow.com/questions/4933285/how-to-determine-python-version-in-makefile
python_version_full := $(wordlist 2,4,$(subst ., ,$(shell python3 --version 2>&1)))
python_version := $(word 1,${python_version_full}).$(word 2,${python_version_full})

program_NAME := pySoftMC
program_CXX_SRCS := $(wildcard ../*.c) $(wildcard ../*.cpp) ./pySoftMC.cpp
program_CXX_OBJS := ${program_CXX_SRCS:.cpp=.o}
program_CXX_OBJS := ${program_CXX_OBJS:.c=.o}
program_OBJS := $(program_CXX_OBJS)

program_INCLUDE_DIRS := . .. /usr/include/python${python_version} ../ext/pybind11/include/pybind11 
program_LIBRARY_DIRS :=
program_LIBRARIES := python${python_version}
CPPFLAGS += -g -std=c++14 -pthread -O3 -fPIC -Wall

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir)) -DPYSMC
LDFLAGS += $(foreach librarydir,$(program_LIBRARY_DIRS),-L$(librarydir))
LDFLAGS += $(foreach library,$(program_LIBRARIES),-l$(library))

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
