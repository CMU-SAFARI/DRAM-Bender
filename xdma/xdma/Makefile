SHELL = /bin/bash
#
# optional makefile parameters:
# - DEBUG=<0|1>,	enable verbose debug print-out in the driver
# - config_bar_num=,	xdma pci config bar number
# - xvc_bar_num=,	xvc pci bar #
# - xvc_bar_offset=,	xvc register base offset
#
ifneq ($(xvc_bar_num),)
	XVC_FLAGS += -D__XVC_BAR_NUM__=$(xvc_bar_num)
endif

ifneq ($(xvc_bar_offset),)
	XVC_FLAGS += -D__XVC_BAR_OFFSET__=$(xvc_bar_offset)
endif

$(warning XVC_FLAGS: $(XVC_FLAGS).)

topdir := $(shell cd $(src)/.. && pwd)

TARGET_MODULE:=xdma

ccflags-y := -I$(src)/../include $(XVC_FLAGS)
ifeq ($(DEBUG),1)
	ccflags-y += -D__LIBXDMA_DEBUG__
endif
ifneq ($(config_bar_num),)
	ccflags-y += -DXDMA_CONFIG_BAR_NUM=$(config_bar_num)
endif
#ccflags-y += -DINTERNAL_TESTING

ifneq ($(KERNELRELEASE),)
	$(TARGET_MODULE)-objs := libxdma.o xdma_cdev.o cdev_ctrl.o cdev_events.o cdev_sgdma.o cdev_xvc.o cdev_bypass.o xdma_mod.o xdma_thread.o
	obj-m := $(TARGET_MODULE).o
else
	KVER ?= $(shell uname -r)
	KDIR ?= /lib/modules/$(KVER)/build
	PWD:=$(shell pwd)
all :
	@test -d "$(KDIR)" || { echo "Kernel build directory not found: $(KDIR)" >&2; exit 1; }
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	@if [ -d "$(KDIR)" ]; then $(MAKE) -C $(KDIR) M=$(PWD) clean; fi
	@/bin/rm -f *.ko modules.order Module.symvers *.mod *.mod.c *.o \
		*.o.ur-safe .*.o .*.o.cmd .*.cmd

install: all
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

endif
