/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * drm/drmP.h was removed from the kernel in 5.5. This keeps the msm-5.4
 * display techpack building on 5.10 by pulling in what the 5.4 header did,
 * minus the headers 5.10 no longer has (drm_os_linux.h, drm_sarea.h,
 * drm_pci.h).
 */
#ifndef _TECHPACK_DISPLAY_DRMP_H_
#define _TECHPACK_DISPLAY_DRMP_H_

#include <linux/cdev.h>
#include <linux/dma-mapping.h>
#include <linux/file.h>
#include <linux/fs.h>
#include <linux/highmem.h>
#include <linux/idr.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/jiffies.h>
#include <linux/kernel.h>
#include <linux/kref.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/poll.h>
#include <linux/ratelimit.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/types.h>
#include <linux/vmalloc.h>
#include <linux/workqueue.h>
#include <linux/dma-fence.h>
#include <linux/module.h>
#include <linux/mman.h>
#include <linux/uaccess.h>

#include <uapi/drm/drm.h>
#include <uapi/drm/drm_mode.h>

#include <drm/drm_agpsupport.h>
#include <drm/drm_crtc.h>
#include <drm/drm_fourcc.h>
#include <drm/drm_hashtab.h>
#include <drm/drm_mm.h>
#include <drm/drm_drv.h>
#include <drm/drm_prime.h>
#include <drm/drm_print.h>
#include <drm/drm_file.h>
#include <drm/drm_debugfs.h>
#include <drm/drm_ioctl.h>
#include <drm/drm_sysfs.h>
#include <drm/drm_vblank.h>
#include <drm/drm_irq.h>
#include <drm/drm_device.h>
#include <drm/drm_bridge.h>
#include <drm/drm_connector.h>
#include <drm/drm_encoder.h>
#include <drm/drm_panel.h>
#include <drm/drm_gem.h>
#include <linux/delay.h>

/* 5.4's drm_debug became __drm_debug in 5.6 */
#define drm_debug __drm_debug

#ifndef DRM_DEBUG_DRIVER_RATELIMITED
#define DRM_DEBUG_DRIVER_RATELIMITED(fmt, ...)				\
({									\
	static DEFINE_RATELIMIT_STATE(_rs,				\
				      DEFAULT_RATELIMIT_INTERVAL,	\
				      DEFAULT_RATELIMIT_BURST);		\
	if (__ratelimit(&_rs))						\
		drm_dev_dbg(NULL, DRM_UT_DRIVER, fmt, ##__VA_ARGS__);	\
})
#endif

#endif
