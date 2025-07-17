#ifndef SOFTMC_DMA_H
#define SOFTMC_DMA_H

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/pci.h>
#include <linux/types.h>
#include <linux/slab.h>
#include <linux/wait.h>
#include <asm/io.h>

#define TRUE (1 == 1)
#define FALSE (1 != 1)

#define VENDOR_ID 		0x10EE
#define DEVICE_ID 		0x7024
#define BUF_LEN	  		64
#define CMD_LEN_OFFSET	16
#define CMD_WRITE		0x0003
#define CMD_READ  		0x0001
#define DMA_BUF_SIZE    4096
#define INTR_BIT_OFFSET 10
#define BUS_BIT_OFFSET  2

#define OFFSET_TXN_REG_LO_ADDR 5
#define OFFSET_TXN_REG_HI_ADDR 4

#define DEBUG

#ifdef DEBUG
#define DBG(msg) printk("%s", msg)
#else
#define DBG(msg) while(false)
#endif

MODULE_AUTHOR("Oguzhan Canpolat");
MODULE_LICENSE("GPL");

typedef struct {
	char *buffer;
	int data_count;
	int start_off;
	int capacity;
} dma_buffer_t;

static dma_buffer_t *send_buff;
static dma_buffer_t *recv_buff;
static int *txn_reg; 
static int last_cmd;
static int last_cmd_done;
static struct pci_dev *dev;
static int *device_id;
static void __iomem *softmc_bar0;
static wait_queue_head_t softmc_wq;

static irqreturn_t irq_handler(int irq, void *dev_id);
int load_recv_buffer(int bytes);
void flush_send_buffer(void);
int write_dma_buffer(void *from, int size);
int read_dma_buffer(void *to, int size);
dma_buffer_t *create_buffer(unsigned long size);
void destroy_buffer(dma_buffer_t *buf);
void disable_interrupt(void);
void enable_interrupt(void);

#endif //SOFTMC_DMA_H