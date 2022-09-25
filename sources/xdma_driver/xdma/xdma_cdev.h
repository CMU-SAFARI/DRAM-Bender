/*
 * This file is part of the Xilinx DMA IP Core driver for Linux
 *
 * Copyright (c) 2016-present,  Xilinx, Inc.
 * All rights reserved.
 *
 * This source code is licensed under both the BSD-style license (found in the
 * LICENSE file in the root directory of this source tree) and the GPLv2 (found
 * in the COPYING file in the root directory of this source tree).
 * You may select, at your option, one of the above-listed licenses.
 */

#ifndef __XDMA_CHRDEV_H__
#define __XDMA_CHRDEV_H__

#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/uaccess.h>
#include <linux/errno.h>
#include "xdma_mod.h"

#define XDMA_NODE_NAME	"xdma"
#define XDMA_MINOR_BASE (0)
#define XDMA_MINOR_COUNT (255)

void xdma_cdev_cleanup(void);
int xdma_cdev_init(void);

int char_open(struct inode *inode, struct file *file);
int char_close(struct inode *inode, struct file *file);
int xcdev_check(const char *, struct xdma_cdev *, bool);

void cdev_ctrl_init(struct xdma_cdev *xcdev);
void cdev_xvc_init(struct xdma_cdev *xcdev);
void cdev_event_init(struct xdma_cdev *xcdev);
void cdev_sgdma_init(struct xdma_cdev *xcdev);
void cdev_bypass_init(struct xdma_cdev *xcdev);

void xpdev_destroy_interfaces(struct xdma_pci_dev *xpdev);
int xpdev_create_interfaces(struct xdma_pci_dev *xpdev);

int bridge_mmap(struct file *file, struct vm_area_struct *vma);

#endif /* __XDMA_CHRDEV_H__ */
