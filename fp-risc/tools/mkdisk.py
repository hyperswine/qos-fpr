"""mkdisk.py -- seed a QLOG disk image with the built .qa apps.

The apps are SEPARATE from System.qa's image: each apps/<Id>.qa is
written as its own QLOG record at url `apps/<Id>.qa`, plus one
`apps/index` record (newline-separated ids) for discovery.  System.qa
boots, scans the log, lists apps from the index, and reads each .qa
off the disk ON DEMAND at launch -- the same storage protocols the kv
streams use, just different urls.  The rodata registry remains only as
the diskless fallback.

Format (mods/qlog.fpr, diskfs.fpr -- unchanged):
  page 0:  "QLOG <head>\n"
  record:  header page "QREC <npages> <paylen> <url>\n" + payload pages

usage: mkdisk.py <disk.img> <size_mb> <app1.qa> [app2.qa ...]
"""
import os, sys

PG = 4096

def main():
    img, size_mb, qas = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
    pages = []

    def record(url, payload: bytes):
        np = (len(payload) + PG - 1) // PG
        pages.append(f"QREC {np} {len(payload)} {url}\n".encode())
        for i in range(np):
            pages.append(payload[i * PG:(i + 1) * PG])

    ids = []
    for qa in qas:
        app_id = os.path.splitext(os.path.basename(qa))[0]
        ids.append(app_id)
        with open(qa, "rb") as f:
            record(f"apps/{app_id}.qa", f.read())
    record("apps/index", ("\n".join(ids) + "\n").encode())

    head = 1 + len(pages)
    out = bytearray(size_mb * 1024 * 1024)
    sb = f"QLOG {head}\n".encode()
    out[0:len(sb)] = sb
    for i, p in enumerate(pages):
        off = (1 + i) * PG
        out[off:off + len(p)] = p
    with open(img, "wb") as f:
        f.write(out)
    print(f"mkdisk: {img} seeded with {len(ids)} apps "
          f"[{', '.join(ids)}] + apps/index (head={head})")

if __name__ == "__main__":
    main()
