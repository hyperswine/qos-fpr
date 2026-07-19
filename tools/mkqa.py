"""mkqa.py -- assemble a .qa (QOS App Archive) from a manifest + ELF.

    tools/mkqa.py <manifest.toml> <app.elf> -o out.qa

The output is the QAR1 container documented in docs/QA-FORMAT.md: magic,
a section table (MANIFEST, ELF), a blank line, then payloads. Both the
launcher (FPRISC) and the diskfs installer read this exact byte layout.

If <app.elf> is '-' or missing, a 1-byte placeholder ELF is bundled --
used while apps are co-compiled and dispatched by name (the ELF section
exists and is hashed, but the running image resolves `entry` by symbol).
"""
import sys, os, argparse

def build(manifest_path, elf_path, out_path):
    with open(manifest_path, "rb") as f:
        manifest = f.read()
    if elf_path and elf_path != "-" and os.path.exists(elf_path):
        with open(elf_path, "rb") as f:
            elf = f.read()
    else:
        elf = b"\x7fELF"  # placeholder: name-dispatch era

    # payloads are laid out MANIFEST then ELF; offsets are relative to
    # the first payload byte
    off = 0
    table_lines = []
    for name, blob in (("MANIFEST", manifest), ("ELF", elf)):
        table_lines.append(f"{name} {off} {len(blob)}")
        off += len(blob)

    header = b"QAR1\n" + ("\n".join(table_lines)).encode() + b"\n\n"
    with open(out_path, "wb") as f:
        f.write(header)
        f.write(manifest)
        f.write(elf)
    print(f"wrote {out_path}: manifest {len(manifest)}B + elf {len(elf)}B "
          f"= {os.path.getsize(out_path)}B total")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("elf", nargs="?", default="-")
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()
    build(a.manifest, a.elf, a.out)
