#!/usr/bin/env python3
"""Compile Altman's lowdefect exporter and write S_n as JSON."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOWDEFECT_DIR = ROOT / "vendor" / "lowdefect"


def build_covering(threshold: int, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ghc", "-O2", "export_covering.hs"], cwd=LOWDEFECT_DIR, check=True)
    exe = LOWDEFECT_DIR / "export_covering.exe"
    if not exe.exists():
        exe = LOWDEFECT_DIR / "export_covering"
    with output.open("w", encoding="ascii") as handle:
        subprocess.run([str(exe), str(threshold)], cwd=LOWDEFECT_DIR, check=True, stdout=handle)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--threshold", type=int, default=46)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "artifacts" / "S_46.json",
        help="JSON output path",
    )
    args = parser.parse_args()
    build_covering(args.threshold, args.output)


if __name__ == "__main__":
    main()

