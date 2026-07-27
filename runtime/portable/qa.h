/* qa.h -- host-side reader for the .qa archive (docs/QA-FORMAT.md).
 *
 * The C analogue of System.qa's FPRISC-side parser: same QAR1 byte
 * layout, same minimal-TOML manifest subset, same launch rules
 * (required permissions are compulsory; optional denials just aren't
 * granted).  Unknown sections are ignored by design. */
#ifndef QOS_QA_H
#define QOS_QA_H

#include <stdint.h>

#define QA_MAX_PERMS 32

typedef struct {
  char url[96];
  char mode[16]; /* read / write / readwrite */
  int required;  /* 1 = [permissions.required], 0 = optional */
  int granted;   /* filled by the permission gate */
} qa_perm_t;

typedef struct {
  /* raw archive (owned by the caller; views below point into it) */
  unsigned char *bytes;
  uint64_t len;
  /* sections */
  const unsigned char *manifest;
  uint64_t manifest_len;
  const unsigned char *elf;
  uint64_t elf_len;
  /* parsed manifest fields */
  char name[64];
  char id[64];
  char load_mode[16]; /* "process" is the only mode qosp runs */
  qa_perm_t perms[QA_MAX_PERMS];
  int nperms;
} qa_t;

/* read + parse; returns 0 ok, -1 with a message on stderr */
int qa_load(const char *path, qa_t *out);
void qa_free(qa_t *qa);

/* serialize the granted set in System.qa's caps format:
 * "appid\nurl mode\n" lines.  Returns bytes written. */
uint64_t qa_caps_serialize(const qa_t *qa, char *out, uint64_t cap);

#endif
