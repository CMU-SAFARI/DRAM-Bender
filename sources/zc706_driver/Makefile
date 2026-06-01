CONFIG_MODULE_SIG=n
CONFIG_MODULE_SIG_ALL=n

TARGET_MODULE := dma_softmc

$(TARGET_MODULE)-objs += softmc_dma.o cdev.o
obj-m += $(TARGET_MODULE).o

all:
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(shell pwd) modules

clean:
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(shell pwd) clean