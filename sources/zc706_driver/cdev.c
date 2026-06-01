#include "cdev.h"
#include "softmc_dma.h"

static int read_offset = 0;

static int softmc_uevent(struct device *dev, struct kobj_uevent_env *env) {
	add_uevent_var(env, "DEVMODE=%#o", 0666);
	return 0;
}

void softmc_cdev_init(void) {
	int err;
	dev_t dev;
	softmc_class = NULL;
	err = alloc_chrdev_region(&dev, 0, 1, "softmc_cdev");
	dev_major = MAJOR(dev);
	softmc_class = class_create(THIS_MODULE, "softmc_cdev");
	softmc_class->dev_uevent = softmc_uevent;
	cdev_init(&driver_data.cdev, &softmc_fops);
	driver_data.cdev.owner = THIS_MODULE;
	cdev_add(&driver_data.cdev, MKDEV(dev_major, 0), 1);
	device_create(softmc_class, NULL, MKDEV(dev_major, 0), NULL, "softmc_cdev", 0);
}

void softmc_cdev_exit(void) {
	device_destroy(softmc_class, MKDEV(dev_major, 0));
	class_unregister(softmc_class);
	class_destroy(softmc_class);
	unregister_chrdev_region(MKDEV(dev_major, 0), 1);
}

int softmc_open(struct inode *inode, struct file *file) {
	printk("SOFTMC: Device open\n");
	return 0;
}

int softmc_release(struct inode *inode, struct file *file) {
	printk("SOFTMC: Device close\n");
	return 0;
}

long softmc_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
	printk("SOFTMC: Device ioctl\n");
	return 0;
}

ssize_t softmc_read(struct file *file, char __user *buf, size_t count, loff_t *offset) {
	int i;
	int n;
	size_t remaining_bytes = count;
	int read_bytes = 0;
	char cdev_buf[CDEV_BUF_LEN];
	#ifdef DEBUG
		printk("READ CALL with count %d.\n", count);
	#endif
	while (remaining_bytes > 0) {
		size_t step_size = remaining_bytes < CDEV_BUF_LEN ? remaining_bytes : CDEV_BUF_LEN;
		n = read_dma_buffer(cdev_buf, step_size);
		copy_to_user((buf + read_bytes), cdev_buf, n);
		if (n < step_size) {
			DBG("Requesting data.\n");
			n = load_recv_buffer(remaining_bytes);
		}
		read_bytes += n;
		remaining_bytes -= n;
	}
	#ifdef DEBUG
		printk("READ CALL completed with %d reads.\n", read_bytes);
	#endif
	return read_bytes;
}

ssize_t softmc_write(struct file *file, const char __user *buf, size_t count, loff_t *offset) {
	int n;
	size_t remaining_bytes = count;
	int sent_bytes = 0;
	char cdev_buf[CDEV_BUF_LEN];
	#ifdef DEBUG
		printk("WRITE CALL with count %d.\n", count);
	#endif
	while (remaining_bytes > 0) {
		size_t step_size = remaining_bytes < CDEV_BUF_LEN ? remaining_bytes : CDEV_BUF_LEN; 
		copy_from_user(cdev_buf, (buf + sent_bytes), step_size);
		n = write_dma_buffer(cdev_buf, step_size);
		if (n < step_size) {
			DBG("Flushing buffer.\n");
			flush_send_buffer();
		}
		sent_bytes += n;
		remaining_bytes -= n;
	}
	#ifdef DEBUG
		printk("WRITE CALL completed with %d sent bytes.\n", sent_bytes);
	#endif
	flush_send_buffer();
	return sent_bytes;
}