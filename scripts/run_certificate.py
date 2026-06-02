#!/usr/bin/env python3
"""Build S_46 and run the near-power verifier."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

from build_covering import build_covering
from lowdefect_certificate.report import write_json_report, write_markdown_report
from verify_near_powers import verify_covering_native


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--threshold", type=int, default=46)
    parser.add_argument("--covering", type=Path, default=ROOT / "artifacts" / "S_46.json")
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--out-json", type=Path, default=ROOT / "artifacts" / "near_power_report.json")
    parser.add_argument("--out-md", type=Path, default=ROOT / "artifacts" / "near_power_report.md")
    args = parser.parse_args()

    if not args.skip_build:
        build_covering(args.threshold, args.covering)
    report = verify_covering_native(args.covering, required_threshold=args.threshold)
    write_json_report(report, args.out_json)
    write_markdown_report(report, args.out_md)
    print(f"checked {report['target_count']} cases; all_excluded={report['all_excluded']}")


if __name__ == "__main__":
    main()
