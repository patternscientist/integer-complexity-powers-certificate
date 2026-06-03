#!/usr/bin/env python3
"""Run the native obstruction analyzer and write a Markdown summary."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NATIVE_SOURCE = ROOT / "native" / "analyze_obstructions.cpp"
NATIVE_EXE = ROOT / "build" / "native_analyze_obstructions.exe"


def build_analyzer() -> Path:
    if shutil.which("g++") is None:
        raise RuntimeError("g++ is not available for the native obstruction analyzer")
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


def sorted_counts(counts: dict[str, int]) -> list[tuple[str, int]]:
    return sorted(counts.items(), key=lambda item: (-int(item[1]), item[0]))


def dominant_count(counts: dict[str, int]) -> tuple[str, int]:
    return sorted_counts(counts)[0]


def write_markdown(summary: dict, hard_cases: dict, out_md: Path) -> None:
    obstruction_counts = summary["obstruction_counts"]
    lines: list[str] = []
    lines.append("# S_46 Obstruction Summary")
    lines.append("")
    lines.append("This is a structural analysis of the existing S_46 near-power certificate.")
    lines.append("It does not change the verifier, the certificate logic, or the mathematical target.")
    lines.append("")
    lines.append("## Headline")
    lines.append("")
    lines.append(f"- Covering: `{summary['covering_path']}`")
    lines.append(f"- Threshold multiple: `{summary['threshold_multiple']}`")
    lines.append(f"- Pairs parsed: `{summary['pair_count']}`")
    lines.append(f"- Pair-target combinations classified: `{summary['pair_target_count']}`")
    lines.append(f"- Max degree: `{summary['max_degree']}`")
    lines.append(f"- Survivors found by analyzer: `{summary['survivor_count']}`")
    lines.append(f"- Hard cases needing bounded exponent enumeration: `{summary['hard_case_count']}`")
    lines.append(f"- Hard case records written: `{hard_cases['recorded_count']}`")
    lines.append("")
    lines.append("## Classification Order")
    lines.append("")
    for name in summary["classification_order"]:
        lines.append(f"- `{name}`: {summary['obstruction_definitions'][name]}")
    lines.append("")
    lines.append("## Obstruction Counts")
    lines.append("")
    lines.append("| Obstruction | Count |")
    lines.append("| --- | ---: |")
    for name, count in sorted_counts(obstruction_counts):
        lines.append(f"| `{name}` | {count} |")
    lines.append("")
    lines.append("## By Degree")
    lines.append("")
    for degree, counts in sorted(summary["by_degree"].items(), key=lambda item: int(item[0])):
        lines.append(f"### Degree {degree}")
        lines.append("")
        lines.append("| Obstruction | Count |")
        lines.append("| --- | ---: |")
        for name, count in sorted_counts(counts):
            lines.append(f"| `{name}` | {count} |")
        lines.append("")
    lines.append("## Base Complexity Buckets")
    lines.append("")
    lines.append("The JSON report contains the full obstruction matrix by base-complexity bucket.")
    lines.append("")
    lines.append("| C bucket | Total pair-targets | Dominant obstruction | Dominant count |")
    lines.append("| --- | ---: | --- | ---: |")
    for bucket, counts in sorted(summary["by_base_complexity_bucket"].items()):
        total = sum(int(value) for value in counts.values())
        dominant, dominant_value = dominant_count(counts)
        lines.append(f"| `{bucket}` | {total} | `{dominant}` | {dominant_value} |")
    lines.append("")
    lines.append("## Target Breakdown")
    lines.append("")
    lines.append("The JSON report contains the full obstruction matrix for every `(m,b)` target.")
    lines.append("")
    lines.append("| Target | Total pair-targets | Dominant obstruction | Dominant count | Hard cases |")
    lines.append("| --- | ---: | --- | ---: | ---: |")
    target_items = sorted(
        summary["by_target"].items(),
        key=lambda item: (
            int(item[0].split("_")[0][1:]),
            int(item[0].split("_")[1][1:]),
        ),
    )
    for target, counts in target_items:
        total = sum(int(value) for value in counts.values())
        dominant, dominant_value = dominant_count(counts)
        hard = int(counts.get("exhaustive_exponent_enumeration_needed", 0))
        lines.append(f"| `{target}` | {total} | `{dominant}` | {dominant_value} | {hard} |")
    lines.append("")
    lines.append("## Modular Details")
    lines.append("")
    if summary["modular_detail_counts"]:
        lines.append("| First failing modulus | Count |")
        lines.append("| --- | ---: |")
        for name, count in sorted_counts(summary["modular_detail_counts"]):
            lines.append(f"| `{name}` | {count} |")
    else:
        lines.append("No pair-target was first excluded by a modular obstruction.")
    lines.append("")
    lines.append("## Top Polynomial Shapes")
    lines.append("")
    shape_totals = [
        (shape, sum(int(value) for value in counts.values()))
        for shape, counts in summary["by_polynomial_shape"].items()
    ]
    lines.append("| Shape signature | Total pair-targets |")
    lines.append("| --- | ---: |")
    for shape, total in sorted(shape_totals, key=lambda item: (-item[1], item[0]))[:30]:
        lines.append(f"| `{shape}` | {total} |")
    lines.append("")
    lines.append("## Hard Cases")
    lines.append("")
    if hard_cases["hard_case_count"] == 0:
        lines.append("No pair-target required bounded exponent enumeration after the exact obstruction filters.")
    else:
        lines.append(
            "Hard cases are written to `artifacts/S_46_hard_cases.json`. "
            "Each record includes the polynomial, base complexity, target, exponent-sum bound, "
            "and exact bounded exponent-tuple search-space size. Closest misses are only populated "
            "when a run explicitly evaluates tuples."
        )
        lines.append("")
        if hard_cases.get("truncated"):
            lines.append(
                f"The hard-case file is truncated: {hard_cases['recorded_count']} of "
                f"{hard_cases['hard_case_count']} records were written."
            )
    lines.append("")
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines) + "\n", encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--covering", type=Path, default=ROOT / "artifacts" / "S_46.json")
    parser.add_argument("--out-json", type=Path, default=ROOT / "artifacts" / "S_46_obstruction_summary.json")
    parser.add_argument("--out-md", type=Path, default=ROOT / "artifacts" / "S_46_obstruction_summary.md")
    parser.add_argument("--hard-cases", type=Path, default=ROOT / "artifacts" / "S_46_hard_cases.json")
    parser.add_argument("--max-hard-records", type=int, default=100000)
    args = parser.parse_args()

    exe = build_analyzer()
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.hard_cases.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            str(exe),
            str(args.covering),
            str(args.out_json),
            str(args.hard_cases),
            str(args.max_hard_records),
        ],
        cwd=ROOT,
        check=True,
    )
    summary = json.loads(args.out_json.read_text(encoding="ascii"))
    hard_cases = json.loads(args.hard_cases.read_text(encoding="ascii"))
    write_markdown(summary, hard_cases, args.out_md)
    print(
        f"classified {summary['pair_target_count']} pair-targets; "
        f"hard_cases={summary['hard_case_count']}; survivors={summary['survivor_count']}"
    )
    print(f"wrote {args.out_json}")
    print(f"wrote {args.out_md}")
    print(f"wrote {args.hard_cases}")


if __name__ == "__main__":
    sys.exit(main())
