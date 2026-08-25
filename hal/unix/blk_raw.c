/* blk_raw.c -- the hosted disk tier (blk_raw.h): qosp.disk as pages.
 *
 * The whole file is mechanism; the numbers are the only decisions:
 *   - pread/pwrite carry their own offsets, so concurrent READS from
 *     any hart thread race against nothing.  Writes are serialized
 *     above by the storage actor being ONE actor (the same single-
 *     writer rule that keeps append-only sound on virt); the mutex
 *     here guards only first-open against two harts discovering the
 *     device at once.
 *   - a short read past a fresh sparse file's materialized extent is
 *     still zeros by contract, so reads zero-fill the tail rather
 *     than failing: an unwritten page IS a zero page.
 *
 * Log lines go through qos_hostlog (the unified log plane): once the
 * app registers its sink, the disk's open story is browsable at
 * /logs/host like every other host-side boot fact. */
#include "blk_raw.h"
#include "hostlog.h"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static pthread_mutex_t blk_mu = PTHREAD_MUTEX_INITIALIZER;
static int blk_fd = -1;
static int blk_tried;
static uint64_t blk_npages;

static void blk_open_locked(void) {
  if (blk_tried) return;
  blk_tried = 1;

  const char *path = getenv("FPR_DISK");
  if (!path || !*path) path = "qosp.disk";

  int fd = open(path, O_RDWR | O_CREAT, 0644);
  if (fd < 0) {
    qos_hostlog("blk: cannot open %s (%s) -- no disk", path, strerror(errno));
    return;
  }

  struct stat st;
  if (fstat(fd, &st) < 0) {
    qos_hostlog("blk: cannot stat %s (%s) -- no disk", path, strerror(errno));
    close(fd);
    return;
  }

  uint64_t size = (uint64_t)st.st_size;
  if (size < QOS_BLK_PAGE) {
    /* fresh (or degenerate) file: size it.  ftruncate gives a sparse
     * zero-filled extent -- an unformatted disk, exactly what a blank
     * qcow-less virtio image is to virt's blk.c. */
    uint64_t mb = 8;
    const char *mbs = getenv("FPR_DISK_MB");
    if (mbs && *mbs) {
      unsigned long v = strtoul(mbs, 0, 10);
      if (v >= 1 && v <= 4096) mb = v;
    }
    size = mb << 20;
    if (ftruncate(fd, (off_t)size) < 0) {
      qos_hostlog("blk: cannot size %s to %lluMB (%s) -- no disk", path,
                  (unsigned long long)mb, strerror(errno));
      close(fd);
      return;
    }
    qos_hostlog("blk: %s created, %llu pages of 4096 bytes", path,
                (unsigned long long)(size / QOS_BLK_PAGE));
  } else {
    qos_hostlog("blk: %s opened, %llu pages of 4096 bytes", path,
                (unsigned long long)(size / QOS_BLK_PAGE));
  }

  blk_fd = fd;
  blk_npages = size / QOS_BLK_PAGE;
}

void qos_blkraw_setup(void) {
  pthread_mutex_lock(&blk_mu);
  blk_open_locked();
  pthread_mutex_unlock(&blk_mu);
}

int64_t qos_blkraw_pages(void) {
  qos_blkraw_setup(); /* idempotent: entries are safe in any order */
  return (int64_t)blk_npages;
}

int64_t qos_blkraw_read(uint64_t page, char *dst) {
  qos_blkraw_setup();
  if (blk_fd < 0 || page >= blk_npages) return -1;
  ssize_t n = pread(blk_fd, dst, QOS_BLK_PAGE, (off_t)(page * QOS_BLK_PAGE));
  if (n < 0) return -1;
  /* sparse tail: unwritten bytes are zero by contract */
  if ((uint64_t)n < QOS_BLK_PAGE) memset(dst + n, 0, QOS_BLK_PAGE - (uint64_t)n);
  return 0;
}

int64_t qos_blkraw_write(uint64_t page, const char *src, uint64_t len) {
  qos_blkraw_setup();
  if (blk_fd < 0 || page >= blk_npages || len > QOS_BLK_PAGE) return -1;
  char buf[QOS_BLK_PAGE];
  memcpy(buf, src, len);
  memset(buf + len, 0, QOS_BLK_PAGE - len); /* whole pages, zero-padded */
  ssize_t n = pwrite(blk_fd, buf, QOS_BLK_PAGE, (off_t)(page * QOS_BLK_PAGE));
  return n == (ssize_t)QOS_BLK_PAGE ? (int64_t)len : -1;
}
