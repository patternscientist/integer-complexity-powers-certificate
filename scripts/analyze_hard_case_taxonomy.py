#!/usr/bin/env python3
"""Exploratory taxonomy for S_46 hard cases.

This script mines artifacts/S_46_hard_cases.json. It does not alter or invoke
the certificate verifier logic.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import Counter, defaultdict
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
MODULI = (16, 64, 81, 243)
UPGRADE_MODULI = (256, 729)
ALL_MODULI = MODULI + UPGRADE_MODULI


@dataclass(frozen=True)
class Node:
    kind: str
    constant: int = 1
    child: "Node | None" = None
    children: tuple["Node", ...] = ()


def matching_paren(text: str, start: int, end: int) -> int:
    depth = 0
    for index in range(start, end):
        char = text[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError(f"unmatched parenthesis in {text!r}")


def parse_int(text: str, pos: int, end: int) -> tuple[int, int]:
    start = pos
    while pos < end and text[pos].isdigit():
        pos += 1
    if start == pos:
        raise ValueError(f"expected integer at {pos} in {text!r}")
    return int(text[start:pos]), pos


def parse_expr(text: str, pos: int = 0, end: int | None = None) -> tuple[Node, int]:
    if end is None:
        end = len(text)
    if pos >= end:
        raise ValueError(f"empty expression in {text!r}")

    if text[pos].isdigit():
        constant, pos = parse_int(text, pos, end)
        children: list[Node] = []
        while pos < end and text[pos] == "(":
            close = matching_paren(text, pos, end)
            child, child_pos = parse_expr(text, pos + 1, close)
            if child_pos != close:
                raise ValueError(f"did not consume child in {text!r}")
            children.append(child)
            pos = close + 1
        return Node("M", constant=constant, children=tuple(children)), pos

    if text[pos] != "(":
        raise ValueError(f"expected '(' or digit at {pos} in {text!r}")

    close = matching_paren(text, pos, end)
    child, child_pos = parse_expr(text, pos + 1, close)
    if child_pos != close:
        raise ValueError(f"did not consume parenthesized child in {text!r}")
    after = close + 1
    marker = "3^_+"
    if text.startswith(marker, after):
        constant, after = parse_int(text, after + len(marker), end)
        return Node("A", constant=constant, child=child), after

    children = [child]
    pos = after
    while pos < end and text[pos] == "(":
        close = matching_paren(text, pos, end)
        child, child_pos = parse_expr(text, pos + 1, close)
        if child_pos != close:
            raise ValueError(f"did not consume product child in {text!r}")
        children.append(child)
        pos = close + 1
    return Node("M", constant=1, children=tuple(children)), pos


@lru_cache(maxsize=None)
def parse_polynomial(text: str) -> Node:
    node, pos = parse_expr(text)
    if pos != len(text):
        raise ValueError(f"trailing input at {pos} in {text!r}")
    return node


@lru_cache(maxsize=None)
def degree(poly: str) -> int:
    return node_degree(parse_polynomial(poly))


def node_degree(node: Node) -> int:
    if node.kind == "A":
        assert node.child is not None
        return 1 + node_degree(node.child)
    return sum(node_degree(child) for child in node.children)


@lru_cache(maxsize=None)
def shape_signature(poly: str) -> str:
    return node_shape(parse_polynomial(poly))


def node_shape(node: Node) -> str:
    if node.kind == "A":
        assert node.child is not None
        return f"A({node_shape(node.child)})"
    if not node.children:
        return "P0"
    return "P(" + "*".join(node_shape(child) for child in node.children) + ")"


def equation_class_from_degree(d: int) -> str:
    if d <= 1:
        return "linear"
    if d == 2:
        return "bilinear"
    return "higher_multilinear"


def c_bucket(value: int) -> str:
    lo = (value // 10) * 10
    return f"C{lo:03d}_{lo + 9:03d}"


def tuple_bucket(value: int) -> str:
    if value < 100:
        return "T000000_000099"
    if value < 1_000:
        return "T000100_000999"
    if value < 10_000:
        return "T001000_009999"
    if value < 100_000:
        return "T010000_099999"
    return "T100000_plus"


def v_p(value: int, prime: int) -> int:
    out = 0
    while value % prime == 0:
        value //= prime
        out += 1
    return out


def eval_node(node: Node, exponents: tuple[int, ...], pos: int = 0) -> tuple[int, int]:
    if node.kind == "A":
        assert node.child is not None
        child_value, pos = eval_node(node.child, exponents, pos + 1)
        return child_value * (3 ** exponents[pos - 1]) + node.constant, pos
    value = node.constant
    for child in node.children:
        child_value, pos = eval_node(child, exponents, pos)
        value *= child_value
    return value, pos


def eval_poly(poly: str, exponents: tuple[int, ...]) -> int:
    value, pos = eval_node(parse_polynomial(poly), exponents)
    if pos != len(exponents):
        raise ValueError("unused exponents")
    return value


def residue_dp_node(node: Node, budget: int, modulus: int) -> tuple[frozenset[int], ...]:
    if node.kind == "A":
        assert node.child is not None
        child_dp = residue_dp_node(node.child, budget, modulus)
        powers = [1 % modulus]
        for _ in range(budget):
            powers.append((powers[-1] * 3) % modulus)
        out: list[set[int]] = [set() for _ in range(budget + 1)]
        for child_used, residues in enumerate(child_dp):
            for exponent in range(budget - child_used + 1):
                dest = out[child_used + exponent]
                power = powers[exponent]
                for residue in residues:
                    dest.add((residue * power + node.constant) % modulus)
        return tuple(frozenset(part) for part in out)

    out: list[set[int]] = [set() for _ in range(budget + 1)]
    out[0].add(node.constant % modulus)
    for child in node.children:
        child_dp = residue_dp_node(child, budget, modulus)
        nxt: list[set[int]] = [set() for _ in range(budget + 1)]
        for left_used, left_residues in enumerate(out):
            if not left_residues:
                continue
            for child_used in range(budget - left_used + 1):
                child_residues = child_dp[child_used]
                if not child_residues:
                    continue
                dest = nxt[left_used + child_used]
                for a in left_residues:
                    for b in child_residues:
                        dest.add((a * b) % modulus)
        out = nxt
    return tuple(frozenset(part) for part in out)


@lru_cache(maxsize=50000)
def residue_dp(poly: str, budget: int, modulus: int) -> tuple[frozenset[int], ...]:
    return residue_dp_node(parse_polynomial(poly), budget, modulus)


def union_size_up_to(dp: tuple[frozenset[int], ...], budget: int) -> int:
    image: set[int] = set()
    for used in range(min(budget, len(dp) - 1) + 1):
        image.update(dp[used])
    return len(image)


def target_possible(poly: str, budget: int, n: int, modulus: int) -> tuple[bool, int, int]:
    dp = residue_dp(poly, budget, modulus)
    max_e = min(v_p(n, 3), budget)
    witness_count = 0
    for e in range(max_e + 1):
        target = (n // (3**e)) % modulus
        for used in range(budget - e + 1):
            if target in dp[used]:
                witness_count += 1
                break
    return witness_count > 0, witness_count, union_size_up_to(dp, budget)


class GroupStats:
    def __init__(self) -> None:
        self.count = 0
        self.bounds: list[int] = []
        self.tuples: list[int] = []
        self.degrees: Counter[int] = Counter()
        self.equation_classes: Counter[str] = Counter()
        self.representatives: list[str] = []

    def add(self, case: dict[str, Any], equation_class: str) -> None:
        self.count += 1
        self.bounds.append(int(case["allowed_exponent_sum_max"]))
        self.tuples.append(int(case["exponent_tuples_checked"]))
        self.degrees[int(case["degree"])] += 1
        self.equation_classes[equation_class] += 1
        poly = str(case["polynomial"])
        if len(self.representatives) < 3 and poly not in self.representatives:
            self.representatives.append(poly)

    def to_json(self) -> dict[str, Any]:
        bounds = sorted(self.bounds)
        tuples = sorted(self.tuples)
        return {
            "count": self.count,
            "exponent_sum_bound": min_median_max(bounds),
            "tuple_search_space": min_median_max(tuples),
            "degree_counts": {str(k): v for k, v in sorted(self.degrees.items())},
            "equation_class_counts": dict(sorted(self.equation_classes.items())),
            "representative_polynomials": self.representatives,
        }


def min_median_max(values: list[int]) -> dict[str, int | float | None]:
    if not values:
        return {"min": None, "median": None, "max": None}
    return {
        "min": values[0],
        "median": statistics.median(values),
        "max": values[-1],
    }


def add_group(groups: dict[str, GroupStats], key: str, case: dict[str, Any], equation_class: str) -> None:
    groups[key].add(case, equation_class)


def summarize_groups(groups: dict[str, GroupStats]) -> dict[str, Any]:
    return {key: groups[key].to_json() for key in sorted(groups)}


def exponent_tuples(deg: int, total: int) -> Iterable[tuple[int, ...]]:
    if deg == 0:
        yield ()
        return
    current = [0] * deg

    def rec(index: int, remaining: int) -> Iterable[tuple[int, ...]]:
        if index == deg:
            yield tuple(current)
            return
        for value in range(remaining + 1):
            current[index] = value
            yield from rec(index + 1, remaining - value)

    yield from rec(0, total)


def closest_miss(case: dict[str, Any]) -> dict[str, Any]:
    poly = str(case["polynomial"])
    deg = int(case["degree"])
    budget = int(case["allowed_exponent_sum_max"])
    n = int(case["N"])
    best: dict[str, Any] | None = None
    checked = 0
    for e in range(min(v_p(n, 3), budget) + 1):
        top_power = 3**e
        for exponents in exponent_tuples(deg, budget - e):
            value = eval_poly(poly, exponents) * top_power
            checked += 1
            signed_gap = n - value
            abs_gap = abs(signed_gap)
            if best is None or abs_gap < best["abs_gap"]:
                best = {
                    "abs_gap": abs_gap,
                    "signed_gap": signed_gap,
                    "value": value,
                    "e": e,
                    "k": list(exponents),
                }
    assert best is not None
    gap = abs(int(best["signed_gap"]))
    best["tuples_evaluated"] = checked
    best["gap_pattern"] = {
        "sign": "positive" if best["signed_gap"] > 0 else "negative" if best["signed_gap"] < 0 else "zero",
        "v2": v_p(gap, 2) if gap else None,
        "v3": v_p(gap, 3) if gap else None,
        "v5": v_p(gap, 5) if gap else None,
        "v7": v_p(gap, 7) if gap else None,
        "mod16": gap % 16 if gap else 0,
        "mod64": gap % 64 if gap else 0,
        "mod81": gap % 81 if gap else 0,
        "mod243": gap % 243 if gap else 0,
    }
    return best


def select_closest_miss_samples(cases: list[dict[str, Any]], top_shape_limit: int = 20) -> list[dict[str, Any]]:
    selected: dict[tuple[int, int, int], dict[str, Any]] = {}
    for case in sorted(cases, key=lambda c: int(c["exponent_tuples_checked"]), reverse=True)[:20]:
        selected[(case["pair_index"], case["m"], case["b"])] = case

    shape_counts = Counter(shape_signature(str(case["polynomial"])) for case in cases)
    top_shapes = {shape for shape, _ in shape_counts.most_common(top_shape_limit)}
    seen_shape: set[str] = set()
    for case in sorted(cases, key=lambda c: (shape_signature(str(c["polynomial"])), -int(c["exponent_tuples_checked"]))):
        shape = shape_signature(str(case["polynomial"]))
        if shape in top_shapes and shape not in seen_shape:
            selected[(case["pair_index"], case["m"], case["b"])] = case
            seen_shape.add(shape)
        if len(seen_shape) == len(top_shapes):
            break

    seen_stratum: set[tuple[int, int]] = set()
    for case in sorted(cases, key=lambda c: -int(c["exponent_tuples_checked"])):
        stratum = (int(case["degree"]), int(case["b"]))
        if stratum not in seen_stratum:
            selected[(case["pair_index"], case["m"], case["b"])] = case
            seen_stratum.add(stratum)
    return list(selected.values())


def residue_analysis(cases: list[dict[str, Any]]) -> dict[str, Any]:
    modulus_stats: dict[int, dict[str, Any]] = {
        modulus: {
            "target_possible": 0,
            "killed": 0,
            "image_sizes": [],
            "witness_e_counts": [],
        }
        for modulus in ALL_MODULI
    }
    upgrade_counts = Counter()
    killed_by_degree: dict[str, Counter[str]] = defaultdict(Counter)
    killed_by_shape: dict[str, Counter[str]] = defaultdict(Counter)

    for index, case in enumerate(cases, 1):
        poly = str(case["polynomial"])
        budget = int(case["allowed_exponent_sum_max"])
        n = int(case["N"])
        shape = shape_signature(poly)
        degree_key = str(case["degree"])
        killed: dict[int, bool] = {}
        for modulus in ALL_MODULI:
            possible, witness_e_count, image_size = target_possible(poly, budget, n, modulus)
            stat = modulus_stats[modulus]
            stat["target_possible"] += int(possible)
            stat["killed"] += int(not possible)
            stat["image_sizes"].append(image_size)
            stat["witness_e_counts"].append(witness_e_count)
            killed[modulus] = not possible

        if killed[256] and killed[729]:
            category = "killed_by_both_256_and_729"
        elif killed[256]:
            category = "killed_by_256_only"
        elif killed[729]:
            category = "killed_by_729_only"
        else:
            category = "survives_256_and_729"
        upgrade_counts[category] += 1
        killed_by_degree[degree_key][category] += 1
        killed_by_shape[shape][category] += 1

        if index % 25000 == 0:
            print(f"residue_cases={index}")

    summarized_moduli = {}
    for modulus, stat in modulus_stats.items():
        image_sizes = sorted(stat.pop("image_sizes"))
        witness_counts = sorted(stat.pop("witness_e_counts"))
        summarized_moduli[str(modulus)] = {
            **stat,
            "image_size": min_median_max(image_sizes),
            "witness_e_count": min_median_max(witness_counts),
        }
    return {
        "moduli": summarized_moduli,
        "previous_modular_filter": {
            "moduli": list(MODULI),
            "hard_cases_survived_all_previous_moduli": all(
                summarized_moduli[str(modulus)]["killed"] == 0 for modulus in MODULI
            ),
            "explanation": (
                "For each hard case and each previous modulus, at least one allowed top exponent e "
                "has N/3^e in the residue image of f under the remaining exponent budget."
            ),
        },
        "upgrade_counts": dict(upgrade_counts),
        "upgrade_counts_by_degree": {key: dict(value) for key, value in sorted(killed_by_degree.items())},
        "upgrade_counts_by_shape_top20": {
            shape: dict(killed_by_shape[shape])
            for shape, _ in Counter({shape: sum(counts.values()) for shape, counts in killed_by_shape.items()}).most_common(20)
        },
    }


def build_taxonomy(cases: list[dict[str, Any]]) -> tuple[dict[str, Any], dict[str, Any]]:
    groups: dict[str, dict[str, GroupStats]] = {
        "by_degree": defaultdict(GroupStats),
        "by_target_b": defaultdict(GroupStats),
        "by_target_m": defaultdict(GroupStats),
        "by_polynomial_shape": defaultdict(GroupStats),
        "by_base_complexity_bucket": defaultdict(GroupStats),
        "by_exponent_sum_bound": defaultdict(GroupStats),
        "by_tuple_search_space_bucket": defaultdict(GroupStats),
    }
    shape_counts: Counter[str] = Counter()
    equation_counts: Counter[str] = Counter()

    for case in cases:
        poly = str(case["polynomial"])
        shape = shape_signature(poly)
        deg = int(case["degree"])
        equation_class = equation_class_from_degree(deg)
        shape_counts[shape] += 1
        equation_counts[equation_class] += 1
        add_group(groups["by_degree"], str(deg), case, equation_class)
        add_group(groups["by_target_b"], str(case["b"]), case, equation_class)
        add_group(groups["by_target_m"], str(case["m"]), case, equation_class)
        add_group(groups["by_polynomial_shape"], shape, case, equation_class)
        add_group(groups["by_base_complexity_bucket"], c_bucket(int(case["base_complexity"])), case, equation_class)
        add_group(groups["by_exponent_sum_bound"], str(case["allowed_exponent_sum_max"]), case, equation_class)
        add_group(
            groups["by_tuple_search_space_bucket"],
            tuple_bucket(int(case["exponent_tuples_checked"])),
            case,
            equation_class,
        )

    top_shapes = []
    for shape, count in shape_counts.most_common(20):
        stats = groups["by_polynomial_shape"][shape].to_json()
        top_shapes.append({"shape": shape, **stats})

    largest = sorted(cases, key=lambda c: int(c["exponent_tuples_checked"]), reverse=True)[:20]
    largest_records = []
    for case in largest:
        poly = str(case["polynomial"])
        largest_records.append(
            {
                "pair_index": case["pair_index"],
                "m": case["m"],
                "b": case["b"],
                "N": case["N"],
                "base_complexity": case["base_complexity"],
                "degree": case["degree"],
                "shape": shape_signature(poly),
                "equation_class_after_freezing": equation_class_from_degree(int(case["degree"])),
                "allowed_exponent_sum_max": case["allowed_exponent_sum_max"],
                "exponent_tuples_checked": case["exponent_tuples_checked"],
                "polynomial": poly,
            }
        )

    taxonomy = {
        "source": "artifacts/S_46_hard_cases.json",
        "scope": "exploratory proof-mining taxonomy; not a theorem and not certificate logic",
        "hard_case_count": len(cases),
        "groupings": {name: summarize_groups(group) for name, group in groups.items()},
        "top_20_shape_signatures": top_shapes,
        "top_20_largest_exponent_search_spaces": largest_records,
        "equation_class_counts": dict(equation_counts),
    }

    representatives = {
        "scope": "representative hard cases and sampled exact closest misses",
        "top_20_shape_signatures": top_shapes,
        "top_20_largest_exponent_search_spaces": largest_records,
    }
    return taxonomy, representatives


def add_closest_miss_samples(cases: list[dict[str, Any]], representatives: dict[str, Any]) -> None:
    samples = select_closest_miss_samples(cases)
    records = []
    gap_patterns: Counter[str] = Counter()
    for index, case in enumerate(samples, 1):
        miss = closest_miss(case)
        pattern = miss["gap_pattern"]
        pattern_key = (
            f"sign={pattern['sign']};v2={pattern['v2']};v3={pattern['v3']};"
            f"mod16={pattern['mod16']};mod81={pattern['mod81']}"
        )
        gap_patterns[pattern_key] += 1
        records.append(
            {
                "pair_index": case["pair_index"],
                "m": case["m"],
                "b": case["b"],
                "N": case["N"],
                "base_complexity": case["base_complexity"],
                "degree": case["degree"],
                "shape": shape_signature(str(case["polynomial"])),
                "allowed_exponent_sum_max": case["allowed_exponent_sum_max"],
                "declared_tuple_search_space": case["exponent_tuples_checked"],
                "polynomial": case["polynomial"],
                "closest_miss": miss,
            }
        )
        print(f"closest_miss_sample={index}/{len(samples)} tuples={miss['tuples_evaluated']}")
    representatives["closest_miss_sampling_policy"] = {
        "full_sweep_feasible": False,
        "reason": (
            "The hard-case file contains 258,136 cases. This exploratory run evaluates exact "
            "closest misses for the union of the 20 largest search spaces, one representative "
            "from each top-20 shape signature, and one representative from each degree/b stratum."
        ),
        "sample_count": len(records),
    }
    representatives["closest_miss_samples"] = records
    representatives["closest_miss_gap_pattern_counts"] = dict(gap_patterns)


def proposed_normal_forms(taxonomy: dict[str, Any], modulus_report: dict[str, Any]) -> list[dict[str, Any]]:
    forms = []
    for item in taxonomy["top_20_shape_signatures"][:8]:
        degree_counts = item["degree_counts"]
        degree_value = max(degree_counts.items(), key=lambda kv: kv[1])[0]
        forms.append(
            {
                "name": f"NF{len(forms) + 1}",
                "shape": item["shape"],
                "degree": int(degree_value),
                "equation_class": equation_class_from_degree(int(degree_value)),
                "hard_case_count": item["count"],
                "typical_exponent_sum_bound": item["exponent_sum_bound"],
                "typical_tuple_search_space": item["tuple_search_space"],
                "proof_mining_note": (
                    "Candidate hard-core family; inspect whether a uniform congruence, "
                    "divisibility, or monotone gap argument can replace explicit exponent enumeration."
                ),
            }
        )
    killed = modulus_report["upgrade_counts"]
    forms.append(
        {
            "name": f"NF{len(forms) + 1}",
            "shape": "modulus-upgrade residual",
            "degree": None,
            "equation_class": "mixed",
            "hard_case_count": killed.get("survives_256_and_729", 0),
            "proof_mining_note": (
                "Cases surviving both mod 256 and mod 729 are the natural residual hard core "
                "after the first stronger-modulus experiment."
            ),
        }
    )
    return forms[:10]


def write_markdown(
    taxonomy: dict[str, Any],
    representatives: dict[str, Any],
    modulus_report: dict[str, Any],
    out_md: Path,
) -> None:
    lines: list[str] = []
    lines.append("# S_46 Hard-Case Taxonomy")
    lines.append("")
    lines.append("Exploratory proof-mining report. This does not alter the certificate verifier and does not claim a theorem.")
    lines.append("")
    lines.append("## Headline")
    lines.append("")
    lines.append(f"- Hard cases: `{taxonomy['hard_case_count']}`")
    lines.append(f"- Closest-miss samples evaluated exactly: `{representatives['closest_miss_sampling_policy']['sample_count']}`")
    lines.append("")
    lines.append("## Equation Classes")
    lines.append("")
    lines.append("| Class | Count |")
    lines.append("| --- | ---: |")
    for key, value in sorted(taxonomy["equation_class_counts"].items()):
        lines.append(f"| `{key}` | {value} |")
    lines.append("")
    lines.append("## Top 20 Hard-Case Shape Signatures")
    lines.append("")
    lines.append("| Rank | Shape | Count | Median B | Median tuples | Class counts |")
    lines.append("| ---: | --- | ---: | ---: | ---: | --- |")
    for rank, item in enumerate(taxonomy["top_20_shape_signatures"], 1):
        lines.append(
            f"| {rank} | `{item['shape']}` | {item['count']} | "
            f"{item['exponent_sum_bound']['median']} | {item['tuple_search_space']['median']} | "
            f"`{item['equation_class_counts']}` |"
        )
    lines.append("")
    lines.append("## Top 20 Largest Exponent Search Spaces")
    lines.append("")
    lines.append("| Rank | Pair | Target | Degree | B | Tuples | Shape |")
    lines.append("| ---: | ---: | --- | ---: | ---: | ---: | --- |")
    for rank, item in enumerate(taxonomy["top_20_largest_exponent_search_spaces"], 1):
        lines.append(
            f"| {rank} | {item['pair_index']} | `m={item['m']}, b={item['b']}` | "
            f"{item['degree']} | {item['allowed_exponent_sum_max']} | "
            f"{item['exponent_tuples_checked']} | `{item['shape']}` |"
        )
    lines.append("")
    lines.append("## Stronger Modulus Experiment")
    lines.append("")
    lines.append("| Category | Count |")
    lines.append("| --- | ---: |")
    for key, value in sorted(modulus_report["upgrade_counts"].items()):
        lines.append(f"| `{key}` | {value} |")
    lines.append("")
    lines.append("| Modulus | Killed | Target possible | Median image size | Median witness e count |")
    lines.append("| ---: | ---: | ---: | ---: | ---: |")
    for modulus, item in modulus_report["moduli"].items():
        lines.append(
            f"| {modulus} | {item['killed']} | {item['target_possible']} | "
            f"{item['image_size']['median']} | {item['witness_e_count']['median']} |"
        )
    lines.append("")
    lines.append("## Proposed Hard-Core Normal Forms")
    lines.append("")
    for form in representatives["proposed_hard_core_normal_forms"]:
        lines.append(
            f"- `{form['name']}`: shape `{form['shape']}`, class `{form['equation_class']}`, "
            f"count `{form['hard_case_count']}`. {form['proof_mining_note']}"
        )
    lines.append("")
    lines.append("## Closest-Miss Sampling")
    lines.append("")
    lines.append(representatives["closest_miss_sampling_policy"]["reason"])
    lines.append("")
    lines.append("| Pair | Target | Degree | B | Tuples evaluated | Signed gap | Gap pattern |")
    lines.append("| ---: | --- | ---: | ---: | ---: | ---: | --- |")
    for item in representatives["closest_miss_samples"][:30]:
        miss = item["closest_miss"]
        pattern = miss["gap_pattern"]
        lines.append(
            f"| {item['pair_index']} | `m={item['m']}, b={item['b']}` | {item['degree']} | "
            f"{item['allowed_exponent_sum_max']} | {miss['tuples_evaluated']} | "
            f"{miss['signed_gap']} | `v2={pattern['v2']}, v3={pattern['v3']}, mod16={pattern['mod16']}, mod81={pattern['mod81']}` |"
        )
    lines.append("")
    lines.append("Full aggregate data are in the adjacent JSON artifacts.")
    lines.append("")
    out_md.write_text("\n".join(lines), encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hard-cases", type=Path, default=ROOT / "artifacts" / "S_46_hard_cases.json")
    parser.add_argument("--out-taxonomy", type=Path, default=ROOT / "artifacts" / "S_46_hard_case_taxonomy.json")
    parser.add_argument("--out-md", type=Path, default=ROOT / "artifacts" / "S_46_hard_case_taxonomy.md")
    parser.add_argument("--out-representatives", type=Path, default=ROOT / "artifacts" / "S_46_hard_case_representatives.json")
    parser.add_argument("--out-modulus", type=Path, default=ROOT / "artifacts" / "S_46_modulus_upgrade_report.json")
    args = parser.parse_args()

    raw = json.loads(args.hard_cases.read_text(encoding="ascii"))
    cases = raw["hard_cases"]
    print(f"loaded_hard_cases={len(cases)}")

    taxonomy, representatives = build_taxonomy(cases)
    print("taxonomy_built=true")
    modulus_report = residue_analysis(cases)
    print("residue_analysis_built=true")
    add_closest_miss_samples(cases, representatives)
    representatives["proposed_hard_core_normal_forms"] = proposed_normal_forms(taxonomy, modulus_report)

    args.out_taxonomy.write_text(json.dumps(taxonomy, indent=2, sort_keys=True) + "\n", encoding="ascii")
    args.out_representatives.write_text(
        json.dumps(representatives, indent=2, sort_keys=True) + "\n",
        encoding="ascii",
    )
    args.out_modulus.write_text(json.dumps(modulus_report, indent=2, sort_keys=True) + "\n", encoding="ascii")
    write_markdown(taxonomy, representatives, modulus_report, args.out_md)
    print(f"wrote {args.out_taxonomy}")
    print(f"wrote {args.out_md}")
    print(f"wrote {args.out_representatives}")
    print(f"wrote {args.out_modulus}")


if __name__ == "__main__":
    main()
