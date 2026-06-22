/*
 * Compatibility helpers for building the XDMA driver against multiple
 * distribution kernel versions.
 */

#ifndef XDMA_COMPAT_H
#define XDMA_COMPAT_H

#include <linux/device.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/uio.h>
#include <linux/version.h>

#if defined(__has_include)
# if __has_include(<linux/rhelversion.h>)
#  include <linux/rhelversion.h>
# endif
#endif

/*
 * Some enterprise distributions backport API changes without matching the
 * upstream LINUX_VERSION_CODE. Prefer their release macros where available.
 */
#if defined(RHEL_RELEASE_CODE)
# define ACCESS_OK_2_ARGS (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
#else
# define ACCESS_OK_2_ARGS (LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
# define HAS_MMIOWB (RHEL_RELEASE_CODE <= RHEL_RELEASE_VERSION(8, 0))
#else
# define HAS_MMIOWB (LINUX_VERSION_CODE <= KERNEL_VERSION(5, 1, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
# define HAS_SWAKE_UP_ONE (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
# define HAS_SWAKE_UP (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 0))
#else
# define HAS_SWAKE_UP_ONE (LINUX_VERSION_CODE >= KERNEL_VERSION(4, 19, 0))
# define HAS_SWAKE_UP (LINUX_VERSION_CODE >= KERNEL_VERSION(4, 6, 0))
#endif

#if defined(RHEL_RELEASE_CODE)
# define PCI_AER_NAMECHANGE (RHEL_RELEASE_CODE >= RHEL_RELEASE_VERSION(8, 3))
#else
# define PCI_AER_NAMECHANGE (LINUX_VERSION_CODE >= KERNEL_VERSION(5, 7, 0))
#endif

static inline struct class *xdma_class_create(const char *name)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)
	return class_create(name);
#else
	return class_create(THIS_MODULE, name);
#endif
}

static inline int xdma_get_user_pages_fast(unsigned long start,
					   int nr_pages,
					   bool write,
					   struct page **pages)
{
	unsigned int gup_flags = write ? FOLL_WRITE : 0;

	return get_user_pages_fast(start, nr_pages, gup_flags, pages);
}

static inline void xdma_iocb_complete(struct kiocb *iocb, long ret, long ret2)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 16, 0)
	iocb->ki_complete(iocb, ret2 ? ret2 : ret);
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(4, 1, 0)
	iocb->ki_complete(iocb, ret, ret2);
#else
	aio_complete(iocb, ret, ret2);
#endif
}

static inline const struct iovec *xdma_iov_iter_iov(struct iov_iter *iter)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)
	return iter_iov(iter);
#else
	return iter->iov;
#endif
}

static inline unsigned long xdma_iov_iter_nr_segs(struct iov_iter *iter)
{
	return iter->nr_segs;
}

static inline loff_t xdma_iov_iter_offset(struct iov_iter *iter)
{
	return iter->iov_offset;
}

static inline int xdma_dma_map_sg(struct pci_dev *pdev,
				  struct scatterlist *sg,
				  int nents,
				  enum dma_data_direction dir)
{
	return dma_map_sg(&pdev->dev, sg, nents, dir);
}

static inline void xdma_dma_unmap_sg(struct pci_dev *pdev,
				     struct scatterlist *sg,
				     int nents,
				     enum dma_data_direction dir)
{
	dma_unmap_sg(&pdev->dev, sg, nents, dir);
}

static inline int xdma_set_dma_mask(struct pci_dev *pdev, u64 mask)
{
	return dma_set_mask(&pdev->dev, mask);
}

static inline int xdma_set_coherent_dma_mask(struct pci_dev *pdev, u64 mask)
{
	return dma_set_coherent_mask(&pdev->dev, mask);
}

static inline void xdma_vm_flags_set(struct vm_area_struct *vma,
				     vm_flags_t flags)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 3, 0)
	vm_flags_set(vma, flags);
#else
	vma->vm_flags |= flags;
#endif
}

#endif /* XDMA_COMPAT_H */
