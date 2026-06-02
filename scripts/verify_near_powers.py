#!/usr/bin/env python3
"""Verify the 32 near-power cases against an exported S_46 covering."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from lowdefect_certificate.report import write_json_report, write_markdown_report
from lowdefect_certificate.verifier import verify_covering


NATIVE_SOURCE = ROOT / "native" / "verify_near_powers.cpp"
NATIVE_EXE = ROOT / "build" / "native_verify_near_powers.exe"


def build_native_verifier() -> Path:
    if shutil.which("g++") is None:
        raise RuntimeError("g++ is not available for native verifier backend")
    NATIVE_EXE.parent.mkdir(parents=True, exist_ok=True)
    needs_build = not NATIVE_EXE.exists()
    if not needs_build:
        needs_build = NATIVE_SOURCE.stat().st_mtime > NATIVE_EXE.stat().st_mtime
    if needs_build:
        subprocess.run(
            [
                "g++",
                "-O2",
                "-std=c++14",
                str(NATIVE_SOURCE),
                "-o",
                str(NATIVE_EXE),
            ],
            cwd=ROOT,
            check=True,
        )
    return NATIVE_EXE


def verify_covering_native(covering: Path, required_threshold: int) -> dict:
    exe = build_native_verifier()
    completed = subprocess.run(
        [str(exe), str(covering)],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    report = json.loads(completed.stdout)
    threshold = int(report.get("threshold_multiple", -1))
    if threshold != required_threshold:
        raise ValueError(f"expected S_{required_threshold}, got S_{threshold}")
    report["covering_path"] = str(covering)
    return report


def normalized_for_backend_comparison(report: dict) -> dict:
    """Remove backend/provenance-only fields before exact self-check compare."""

    normalized = json.loads(json.dumps(report, sort_keys=True))
    normalized.pop("backend", None)
    normalized.pop("covering_path", None)
    normalized.pop("declared_pair_count", None)
    return normalized


def run_self_check(covering: Path, threshold: int, out_json: Path) -> dict:
    native_report = verify_covering_native(covering, threshold)
    python_report = verify_covering(covering, required_threshold=threshold)
    native_normalized = normalized_for_backend_comparison(native_report)
    python_normalized = normalized_for_backend_comparison(python_report)
    native_blob = json.dumps(native_normalized, sort_keys=True, separators=(",", ":"))
    python_blob = json.dumps(python_normalized, sort_keys=True, separators=(",", ":"))
    equal = native_blob == python_blob
    report = {
        "self_check": "native_vs_python_exact",
        "covering": str(covering),
        "threshold": threshold,
        "normalized_reports_equal": equal,
        "normalized_sha256": hashlib.sha256(native_blob.encode("utf-8")).hexdigest() if equal else None,
        "native_backend": native_report.get("backend"),
        "native_pair_count": native_report.get("pair_count"),
        "python_pair_count": python_report.get("pair_count"),
        "native_certificate_succeeded": native_report.get("certificate_succeeded"),
        "python_certificate_succeeded": python_report.get("certificate_succeeded"),
        "native_report": native_report,
        "python_report": python_report,
    }
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="ascii")
    if not equal:
        raise RuntimeError(f"native and pure Python verifier reports differ; wrote {out_json}")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--covering", type=Path, default=ROOT / "artifacts" / "S_46.json")
    parser.add_argument("--required-threshold", type=int, default=46)
    parser.add_argument("--out-json", type=Path, default=ROOT / "artifacts" / "near_power_report.json")
    parser.add_argument("--out-md", type=Path, default=ROOT / "artifacts" / "near_power_report.md")
    parser.add_argument("--max-solutions-per-case", type=int, default=20)
    parser.add_argument("--self-check", action="store_true", help="Compare native and pure Python backends on a small covering.")
    parser.add_argument("--self-check-covering", type=Path, default=ROOT / "artifacts" / "S_10.json")
    parser.add_argument("--self-check-threshold", type=int, default=10)
    parser.add_argument(
        "--self-check-out",
        type=Path,
        default=ROOT / "artifacts" / "verifier_self_check_S10.json",
    )
    parser.add_argument(
        "--backend",
        choices=["auto", "native", "python"],
        default="auto",
        help="Verifier backend. auto uses the native exact verifier for large coverings.",
    )
    args = parser.parse_args()

    if args.self_check:
        report = run_self_check(args.self_check_covering, args.self_check_threshold, args.self_check_out)
        print(
            f"self_check={report['normalized_reports_equal']}; "
            f"threshold={report['threshold']}; pair_count={report['native_pair_count']}; "
            f"wrote {args.self_check_out}"
        )
        return

    backend = args.backend
    if backend == "auto":
        backend = "native" if args.covering.exists() and args.covering.stat().st_size > 50_000_000 else "python"

    if backend == "native":
        report = verify_covering_native(args.covering, args.required_threshold)
    else:
        report = verify_covering(
            args.covering,
            required_threshold=args.required_threshold,
            max_solutions_per_case=args.max_solutions_per_case,
        )
    write_json_report(report, args.out_json)
    write_markdown_report(report, args.out_md)
    print(
        f"backend={report.get('backend', backend)}; "
        f"checked {report['target_count']} cases; all_excluded={report['all_excluded']}; "
        f"certificate_succeeded={report.get('certificate_succeeded', False)}"
    )
    print(f"wrote {args.out_json}")
    print(f"wrote {args.out_md}")


if __name__ == "__main__":
    main()
