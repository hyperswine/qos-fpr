/* blkraw_check.c -- host-side proof of the stage-1 disk tier, driving
 * qos_blkraw_* exactly the way qos/appside/hal.c's shims do.  Run via
 * tests-host/blkraw-check.sh, which invokes it twice (persistence is a
 * two-boot property) and against an mkdisk.py-seeded image (format
 * interop is the whole point: qosp.disk IS native's disk.img).
 *
 *   blkraw_check boot1   -- fresh disk: create, format check (page 0
 *                           zero -> "unformatted"), write a QLOG
 *                           superblock + one 2-page record the way
 *                           qlog.fpr's appendRec lays it out, verify
 *                           zero-pad + OOR/oversize refusals
 *   blkraw_check boot2   -- reopen: superblock + record survive,
 *                           payload bytes identical
 *   blkraw_check seeded  -- read an mkdisk.py image: superblock head,
 *                           walk records, find apps/index
 */
#include "blk_raw.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* hostlog stub: keep the harness free of the real hostlog's sink */
void qos_hostlog(const char *fmt, ...);

static int fails;
#define CHECK(cond, name)                                   \
  do {                                                      \
    if (cond) printf("  ok   %s\n", name);                  \
    else { printf("  FAIL %s\n", name); fails++; }          \
  } while (0)

static char pg[QOS_BLK_PAGE], pg2[QOS_BLK_PAGE];

static int boot1(void) {
  int64_t n = qos_blkraw_pages();
  CHECK(n == 2048, "fresh disk: 8MB = 2048 pages"); /* FPR_DISK_MB unset */

  qos_blkraw_read(0, pg);
  int allz = 1;
  for (unsigned i = 0; i < QOS_BLK_PAGE; i++) allz &= pg[i] == 0;
  CHECK(allz, "fresh page 0 is zeros (unformatted superblock)");

  /* lay out what qlog.fpr's ensure + appendRec would: superblock,
   * one record with a 5000-byte payload (2 pages) */
  CHECK(qos_blkraw_write(0, "QLOG 4\n", 7) == 7, "superblock write accepted");
  CHECK(qos_blkraw_write(1, "QREC 2 5000 qdisk/big\n", 22) == 22, "header write");
  char pay[5000];
  for (int i = 0; i < 5000; i++) pay[i] = (char)('a' + i % 26);
  CHECK(qos_blkraw_write(2, pay, QOS_BLK_PAGE) == QOS_BLK_PAGE, "payload page 1");
  CHECK(qos_blkraw_write(3, pay + QOS_BLK_PAGE, 5000 - QOS_BLK_PAGE) ==
            5000 - QOS_BLK_PAGE,
        "payload page 2 (partial, zero-padded)");

  /* the shim's refusal surface */
  CHECK(qos_blkraw_write(n, pg, 8) == -1, "write out of range refused");
  CHECK(qos_blkraw_read((uint64_t)n, pg) == -1, "read out of range refused");
  CHECK(qos_blkraw_write(4, pg, QOS_BLK_PAGE + 1) == -1, "oversize refused");

  /* zero-pad law: bytes past a short write read back as zeros */
  qos_blkraw_read(0, pg);
  CHECK(!memcmp(pg, "QLOG 4\n", 7) && pg[7] == 0 && pg[4095] == 0,
        "short write zero-padded to the whole page");
  return fails;
}

static int boot2(void) {
  int64_t n = qos_blkraw_pages();
  CHECK(n == 2048, "reopen: capacity preserved");
  qos_blkraw_read(0, pg);
  CHECK(!memcmp(pg, "QLOG 4\n", 7), "superblock survived the boot");
  qos_blkraw_read(1, pg);
  CHECK(!memcmp(pg, "QREC 2 5000 qdisk/big\n", 22), "record header survived");
  qos_blkraw_read(2, pg);
  qos_blkraw_read(3, pg2);
  int ok = 1;
  for (int i = 0; i < 5000; i++) {
    char want = (char)('a' + i % 26);
    char got = i < (int)QOS_BLK_PAGE ? pg[i] : pg2[i - QOS_BLK_PAGE];
    ok &= got == want;
  }
  for (unsigned i = 5000 - QOS_BLK_PAGE; i < QOS_BLK_PAGE; i++) ok &= pg2[i] == 0;
  CHECK(ok, "5000-byte payload identical across boots, tail zeros");
  return fails;
}

static int seeded(void) {
  /* an mkdisk.py image: page 0 "QLOG <head>", then QREC records --
   * walk them the way qlog.fpr's scanIdx does and find apps/index */
  qos_blkraw_read(0, pg);
  CHECK(!memcmp(pg, "QLOG ", 5), "seeded superblock recognized");
  long head = strtol(pg + 5, 0, 10);
  CHECK(head > 1, "seeded head past the superblock");
  int found_index = 0, recs = 0;
  for (long p = 1; p < head;) {
    if (qos_blkraw_read((uint64_t)p, pg) < 0) break;
    long np, pl;
    char url[256];
    if (sscanf(pg, "QREC %ld %ld %255s", &np, &pl, url) != 3) break;
    recs++;
    if (!strcmp(url, "apps/index")) {
      qos_blkraw_read((uint64_t)(p + 1), pg2);
      pg2[pl < (long)QOS_BLK_PAGE ? pl : QOS_BLK_PAGE - 1] = 0;
      printf("  apps/index = %s", pg2);
      found_index = 1;
    }
    p += 1 + np;
  }
  CHECK(recs >= 2, "walked the seeded records");
  CHECK(found_index, "apps/index present (the System.qa discovery record)");
  return fails;
}

int main(int argc, char **argv) {
  if (argc < 2) return fprintf(stderr, "mode?\n"), 2;
  printf("blkraw_check %s (FPR_DISK=%s)\n", argv[1],
         getenv("FPR_DISK") ? getenv("FPR_DISK") : "qosp.disk");
  int f = !strcmp(argv[1], "boot1")   ? boot1()
          : !strcmp(argv[1], "boot2") ? boot2()
          : !strcmp(argv[1], "seeded") ? seeded()
                                       : 1;
  printf("%s: %s\n", argv[1], f ? "FAIL" : "ALL PASS");
  return f ? 1 : 0;
}
