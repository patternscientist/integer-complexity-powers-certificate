"""Report writers for certificate artifacts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def write_json_report(report: dict[str, Any], path: str | Path) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="ascii") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")


def write_markdown_report(report: dict[str, Any], path: str | Path) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Near-power certificate report",
        "",
        f"- Covering: `{report['covering_path']}`",
        f"- Backend: `{report.get('backend', 'python_exact')}`",
        f"- Threshold: `S_{report['threshold_multiple']}`",
        f"- Pairs/polynomials: `{report['pair_count']}`",
        f"- Max degree: `{report['max_degree']}`",
        f"- Degree histogram: `{report['degree_histogram']}`",
        f"- Target cases checked: `{report['target_count']}`",
        f"- All cases excluded by supplied covering: `{report['all_excluded']}`",
        f"- S_46 certificate succeeded: `{report.get('certificate_succeeded', False)}`",
        "",
        "## Cases",
        "",
        "| m | b | N | bound | excluded | survivors |",
        "|---:|---:|---:|---:|:---:|---:|",
    ]
    for case in report["cases"]:
        lines.append(
            "| {m} | {b} | {N} | {complexity_bound} | {excluded} | {survivors} |".format(
                survivors=len(case.get("survivors", [])),
                m=case["m"],
                b=case["b"],
                N=case["N"],
                complexity_bound=case["complexity_bound"],
                excluded=case["excluded"],
            )
        )
    survivors = [s for case in report["cases"] for s in case["survivors"]]
    if survivors:
        lines.extend(["", "## Surviving Representations", ""])
        for case in report["cases"]:
            for survivor in case["survivors"]:
                lines.append(
                    "- `N={}` from pair `{}`: `e={}`, `k={}`, complexity `{}`, polynomial `{}`".format(
                        case["N"],
                        survivor["pair_index"],
                        survivor["e"],
                        survivor["k"],
                        survivor["complexity"],
                        survivor["polynomial"],
                    )
                )
    target.write_text("\n".join(lines) + "\n", encoding="ascii")
