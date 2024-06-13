#ifndef CDEV_H
#define CDEV_H

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/workqueue.h>

#define CDEV_BUF_LEN 256

struct softmc_data {
	struct cdev cdev;
};

void softmc_cdev_init(void);
void softmc_cdev_exit(void);
int softmc_open(struct inode *inode, struct file *file);
int softmc_release(struct inode *inode, struct file *file);
long softmc_ioctl(struct file *file, unsigned int cmd, unsigned long arg);
ssize_t softmc_read(struct file *file, char __user *buf, size_t count, loff_t *offset);
ssize_t softmc_write(struct file *file, const char __user *buf, size_t count, loff_t *offset);

static const struct file_operations softmc_fops = {
	.owner = THIS_MODULE,
	.open = softmc_open,
	.release = softmc_release,
	.unlocked_ioctl = softmc_ioctl,
	.read = softmc_read,
	.write = softmc_write
};

static int dev_major;
static struct class *softmc_class;
static struct softmc_data driver_data;

#endif //CDEV_H