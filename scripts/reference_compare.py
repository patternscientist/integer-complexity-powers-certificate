#!/usr/bin/env python3
"""Compare pristine Altman dLT exports against the optimized vendored copy."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
EXPORT_SOURCE = ROOT / "vendor" / "lowdefect" / "export_covering.hs"
REFERENCE_DIR = ROOT / "vendor" / "lowdefect_original"
OPTIMIZED_DIR = ROOT / "vendor" / "lowdefect"
BUILD_DIR = ROOT / "build" / "reference_compare"


def compile_exporter(source_dir: Path, label: str) -> Path:
    out_dir = BUILD_DIR / label
    out_dir.mkdir(parents=True, exist_ok=True)
    exe = out_dir / f"export_covering_{label}.exe"
    subprocess.run(
        [
            "ghc",
            "-O2",
            f"-i{source_dir}",
            "-outputdir",
            str(out_dir),
            "-odir",
            str(out_dir),
            "-hidir",
            str(out_dir),
            "-o",
            str(exe),
            str(EXPORT_SOURCE),
        ],
        cwd=ROOT,
        check=True,
    )
    return exe


def export_threshold(exe: Path, threshold: int, out: Path) -> tuple[dict[str, Any], float]:
    out.parent.mkdir(parents=True, exist_ok=True)
    start = time.perf_counter()
    with out.open("w", encoding="ascii") as handle:
        subprocess.run([str(exe), str(threshold)], cwd=ROOT, stdout=handle, check=True)
    elapsed = time.perf_counter() - start
    return json.loads(out.read_text(encoding="ascii")), elapsed


def canonical_pair_set(data: dict[str, Any]) -> list[str]:
    return sorted(
        json.dumps(pair, sort_keys=True, separators=(",", ":")) for pair in data["pairs"]
    )


def compare_one(ref: dict[str, Any], opt: dict[str, Any]) -> dict[str, Any]:
    ref_set = canonical_pair_set(ref)
    opt_set = canonical_pair_set(opt)
    ref_degrees = [pair["degree"] for pair in ref["pairs"]]
    opt_degrees = [pair["degree"] for pair in opt["pairs"]]
    return {
        "threshold": ref["threshold_multiple"],
        "same_pair_count": ref["pair_count"] == opt["pair_count"],
        "reference_pair_count": ref["pair_count"],
        "optimized_pair_count": opt["pair_count"],
        "same_max_degree": max(ref_degrees, default=0) == max(opt_degrees, default=0),
        "reference_max_degree": max(ref_degrees, default=0),
        "optimized_max_degree": max(opt_degrees, default=0),
        "same_canonical_pair_set": ref_set == opt_set,
        "missing_from_optimized": ref_set[:0] if ref_set == opt_set else sorted(set(ref_set) - set(opt_set))[:5],
        "extra_in_optimized": opt_set[:0] if ref_set == opt_set else sorted(set(opt_set) - set(ref_set))[:5],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-threshold", type=int, default=12)
    parser.add_argument("--out-json", type=Path, default=ROOT / "artifacts" / "reference_compare.json")
    parser.add_argument("--export-dir", type=Path, default=ROOT / "artifacts" / "reference_compare")
    args = parser.parse_args()

    if not REFERENCE_DIR.exists():
        raise SystemExit(f"missing pristine reference directory: {REFERENCE_DIR}")

    ref_exe = compile_exporter(REFERENCE_DIR, "original")
    opt_exe = compile_exporter(OPTIMIZED_DIR, "optimized")
    rows: list[dict[str, Any]] = []

    for threshold in range(1, args.max_threshold + 1):
        ref_data, ref_elapsed = export_threshold(
            ref_exe, threshold, args.export_dir / f"original_S_{threshold}.json"
        )
        opt_data, opt_elapsed = export_threshold(
            opt_exe, threshold, args.export_dir / f"optimized_S_{threshold}.json"
        )
        row = compare_one(ref_data, opt_data)
        row["reference_elapsed_s"] = ref_elapsed
        row["optimized_elapsed_s"] = opt_elapsed
        rows.append(row)
        print(
            "S_{threshold}: count {optimized_pair_count}, max degree {optimized_max_degree}, "
            "same={same_canonical_pair_set}".format(**row)
        )

    report = {
        "max_threshold": args.max_threshold,
        "all_same": all(row["same_canonical_pair_set"] for row in rows),
        "rows": rows,
    }
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="ascii")
    if not report["all_same"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
