#include "softmc_dma.h"
#include "cdev.h"

static irqreturn_t irq_handler(int irq, void *dev_id) {
	int i;
	disable_interrupt();
	DBG("Interrupt received.\n");
	printk("IRQ: %d DEV_ID:%4x\n", irq, *((int *)dev_id));
	last_cmd_done = TRUE;
	DBG("Waking up devices.\n");
	wake_up_all(&softmc_wq);
	enable_interrupt();
	return IRQ_HANDLED;
}

static int __init init_softmc_dma(void) {
	printk(KERN_INFO "Loading DMA Module.\n");
	printk("---------------------------\n\n\n");
	int nvec;
	int err;
	device_id = (int *) kmalloc(sizeof(int), GFP_KERNEL);
	dev = pci_get_device(VENDOR_ID, DEVICE_ID, dev);
	if (dev == NULL) {
		printk("pci_softmc - device not available\n");
		return -1;
	}
	if (pci_enable_device(dev) < 0) {
		printk("pci_softmc - can not enable device\n");
		return -1;
	}
	u16 val = 0;
	pci_read_config_word(dev, PCI_VENDOR_ID, &val);
	printk("pci_softmc - VENDOR ID: 0x%x\n", val);
	pci_read_config_word(dev, PCI_DEVICE_ID, &val);
	*device_id = val;
	printk("pci_softmc - DEVICE ID: 0x%x\n", val);
	pci_read_config_word(dev, PCI_COMMAND, &val);
	printk("pci_softmc - COMMAND: 0x%x\n", val);
	pci_release_region(dev, 0);
	if (pci_request_region(dev, 0, "pci_softmc_bar0")) {
		printk("pci_softmc - could not request BAR0\n");
		return -1;
	}
	softmc_bar0 = pci_iomap(dev, 0, pci_resource_len(dev, 0));
	printk("pci_softmc - bar size is %lld\n", pci_resource_len(dev, 0));
	printk("pci_softmc - current_state: %d\n", dev->current_state);
	printk("pci_softmc - pci_msi_vec_count: %d\n", pci_msi_vec_count(dev));
	printk("pci_softmc - msi_enabled: %d\n", dev->msi_enabled);
	printk("pci_softmc - msix_enabled: %d\n", dev->msix_enabled);
	printk("pci_softmc - dev->irq: %d\n", dev->irq);
	err = request_irq(dev->irq, irq_handler, 0, "PCI_FPGA_SOFTMC", device_id);
	printk("pci_softmc - request IRQ: %d\n", err);
	send_buff = create_buffer(DMA_BUF_SIZE);
	recv_buff = create_buffer(DMA_BUF_SIZE);
	init_waitqueue_head(&softmc_wq);
	softmc_cdev_init();
	txn_reg = (int *) kmalloc(sizeof(int), GFP_DMA);
	uint64_t txn_reg_addr = virt_to_phys(txn_reg);
	iowrite32((u32) (txn_reg_addr >> 32), softmc_bar0 + OFFSET_TXN_REG_LO_ADDR);
	iowrite32((u32) (txn_reg_addr & 0xFFFFFFFF), softmc_bar0 + OFFSET_TXN_REG_HI_ADDR);
	printk(KERN_INFO "Loaded DMA Module.\n");
	enable_interrupt();
	return 0;
}

static void __exit exit_softmc_dma(void) {
	printk(KERN_INFO "Unloading DMA Module.\n");
	free_irq(dev->irq, device_id);
	printk("pci_softmc - freed IRQ\n");
	pci_release_region(dev, 0);
	printk("pci_softmc - released BARs\n");
	softmc_cdev_exit();
	destroy_buffer(send_buff);
	destroy_buffer(recv_buff);
	printk(KERN_INFO "Unloaded DMA Module.\n");
}

int write_dma_buffer(void *from, int size) {
	dma_buffer_t *buf = send_buff;
	if (!buf) {
		printk("Invalid dma buffer.\n");
	}
	if (!from) {
		printk("Invalid target buffer.\n");
	}
	const char *src = from;
	int write_count = 0;
	int available_bytes = buf->capacity - buf->data_count;
	if (size > available_bytes) {
		size = available_bytes;
	}
#ifdef DEBUG
	printk("size: %d\tavailable_bytes: %d\n", size, available_bytes);
#endif
	while (write_count < size) {
		writeb(*(src + write_count), (buf->buffer + ((buf->start_off + write_count) % buf->capacity)));
		write_count++;
	} 
	buf->data_count += write_count;
#ifdef DEBUG
	printk("WRITING DMA BUFFER:\n");
	printk("start_off: %d\tdata_count: %d\n", buf->start_off, buf->data_count);
#endif
	return write_count;
}

int read_dma_buffer(void *to, int size) {
	dma_buffer_t *buf = recv_buff;
	if (!buf) {
		printk("Invalid dma buffer.\n");
	}
	if (!to) {
		printk("Invalid target buffer.\n");
	}
	int read_count = 0;
	int available_bytes = buf->data_count;
	char *dst = to;
	if (size > available_bytes) {
		size = available_bytes;
	}
#ifdef DEBUG
	printk("size: %d\tavailable_bytes: %d\n", size, available_bytes);
#endif
	while (read_count < size) {
		writeb(*(buf->buffer + ((buf->start_off + read_count) % buf->capacity)), (dst + read_count));
		read_count++;
	}
	buf->start_off = (buf->start_off + read_count) % buf->capacity;
	buf->data_count -= read_count;
#ifdef DEBUG
	printk("READ DMA BUFFER:\n");
	printk("start_off: %d\tdata_count: %d\n", buf->start_off, buf->data_count);
#endif
	return read_count;
}

dma_buffer_t *create_buffer(unsigned long size) {
	dma_buffer_t *buf = (dma_buffer_t *) kmalloc(sizeof(dma_buffer_t), GFP_KERNEL);
	if (!buf) {
		printk("Could not create dma_buffer_t\n");
		return NULL;
	}
	buf->buffer = (void *) kmalloc(size, GFP_DMA);
	if (!buf->buffer) {
		printk("Could not create buffer\n");
		return NULL;
	}
	buf->capacity = size;
	buf->data_count = 0;
	buf->start_off = 0;
	return buf;
}

void destroy_buffer(dma_buffer_t *buf) {
	kfree(buf->buffer);
	kfree(buf);
}

int load_recv_buffer(int size) {
	int i;
	int available_size = recv_buff->capacity - recv_buff->data_count;
	if (size > available_size) {
		size = available_size;
	}
	last_cmd = CMD_WRITE;
	last_cmd_done = FALSE;
	uint64_t send_phy_addr = virt_to_phys(recv_buff->buffer);
	iowrite32((u32) (send_phy_addr >> 32), softmc_bar0 + 4);
	iowrite32((u32) (send_phy_addr & 0xFFFFFFFF), softmc_bar0 + 8);
	iowrite32((u32) ((sizeof(char) * available_size) << CMD_LEN_OFFSET | CMD_WRITE), softmc_bar0);
	recv_buff->start_off = 0;
	recv_buff->data_count = size;
	DBG("Waiting for DMA load\n");
	wait_event_interruptible(softmc_wq, last_cmd_done);
	DBG("DMA loaded\n");
	return size;
}

void flush_send_buffer(void) {
	last_cmd = CMD_READ;
	last_cmd_done = FALSE;
	uint64_t send_phy_addr = virt_to_phys(send_buff->buffer);
	iowrite32((u32) (send_phy_addr >> 32), softmc_bar0 + 4);
	iowrite32((u32) (send_phy_addr & 0xFFFFFFFF), softmc_bar0 + 8);
	iowrite32((u32) ((sizeof(char) * send_buff->data_count) << CMD_LEN_OFFSET | CMD_READ), softmc_bar0);
	send_buff->data_count = 0;
	DBG("Waiting for DMA write\n");
	wait_event_interruptible(softmc_wq, last_cmd_done);
	DBG("DMA written\n");
}

void disable_interrupt(void) {
	u16 reg;
	pci_read_config_word(dev, PCI_COMMAND, &reg);
	reg = reg | (1ULL << INTR_BIT_OFFSET);
	pci_write_config_word(dev, PCI_COMMAND, reg);
}

void enable_interrupt(void) {
	u16 reg;
	pci_read_config_word(dev, PCI_COMMAND, &reg);
	reg = reg & ~(1ULL << INTR_BIT_OFFSET);
	pci_write_config_word(dev, PCI_COMMAND, reg);
}

module_init(init_softmc_dma);
module_exit(exit_softmc_dma);