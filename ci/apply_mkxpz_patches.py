#!/usr/bin/env python3
"""Apply patches/mkxpz-*.patch to a pristine mkxp-z 2.4.2 tree, in patches/ORDEN.txt order.

Reuses cabeceras()/donde_aplicar() from the repo's reconstruir-src.py so patch
placement matches what the author verified.

Settings are edited here, not passed on the command line.
"""
import importlib.util, os, subprocess, sys

# ----------------------------- SETTINGS ------------------------------------
REPO_ROOT = os.environ.get("REPO_ROOT", os.getcwd())          # repo checkout
TREE      = os.environ.get("MKXPZ_TREE", os.path.join(REPO_ROOT, "src", "mkxp-z"))
# ---------------------------------------------------------------------------

spec = importlib.util.spec_from_file_location("reconstruir", os.path.join(REPO_ROOT, "reconstruir-src.py"))
rec = importlib.util.module_from_spec(spec); spec.loader.exec_module(rec)

orden = [l.strip() for l in open(os.path.join(REPO_ROOT, "patches", "ORDEN.txt"), encoding="utf-8")
         if l.strip() and not l.startswith("#")]
on_disk = {os.path.basename(p) for p in __import__("glob").glob(os.path.join(REPO_ROOT, "patches", "mkxpz-*.patch"))}
missing = [n for n in orden if n not in on_disk]
extra = sorted(on_disk - set(orden))
if missing: sys.exit("ORDEN.txt names patches that do not exist: %s" % missing)
if extra: print("WARNING: patches not listed in ORDEN.txt (skipped): %s" % extra)

failed = []
for name in orden:
    p = os.path.join(REPO_ROOT, "patches", name)
    cwd, nivel = rec.donde_aplicar(TREE, p)
    if cwd is None:
        failed.append((name, "cannot locate target file")); print("FAIL  %s (cannot locate target)" % name); continue
    cmd = ["patch", "-p%d" % nivel, "-s", "-f", "--no-backup-if-mismatch", "-i", p]
    r = subprocess.run(cmd + ["--dry-run"], cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        # CRLF-tolerant retry: the port's .c/.cpp files were CRLF on the author's machine
        r2 = subprocess.run(cmd + ["--dry-run", "--ignore-whitespace"], cwd=cwd, capture_output=True, text=True)
        if r2.returncode != 0:
            failed.append((name, (r.stdout + r.stderr).strip()[:300])); print("FAIL  %s" % name); continue
        cmd.append("--ignore-whitespace")
    subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True)
    print("ok    %s" % name)

print("\napplied %d of %d" % (len(orden) - len(failed), len(orden)))
if failed:
    for n, why in failed: print("  FAILED %s: %s" % (n, why))
    sys.exit(1)
