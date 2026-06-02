"""Exact verifier for the 32 near-power low-defect representation exclusions."""

from __future__ import annotations

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any

from .factor import divisors, v_p
from .families import (
    TreeKey,
    degree,
    evaluate,
    max_coefficient,
    product,
    pretty,
    sum_coefficients,
    term_count,
    tree_key,
)

TARGET_B_VALUES = (1, 6, 8, 9)


@dataclass(frozen=True)
class TargetCase:
    m: int
    b: int

    @property
    def n(self) -> int:
        return 2**self.m - self.b

    @property
    def complexity_bound(self) -> int:
        return 2 * self.m - 2


@dataclass(frozen=True)
class Pair:
    index: int
    base_complexity: int
    degree: int
    tree: TreeKey


@dataclass(frozen=True)
class Representation:
    pair_index: int
    e: int
    exponents: tuple[int, ...]
    complexity: int
    polynomial: str


def certificate_success_conditions(
    *,
    threshold: int,
    pair_count_matches_declared: bool,
    max_degree: int | None,
    target_count: int,
    all_excluded: bool,
    survivors_empty: bool,
) -> bool:
    return (
        threshold == 46
        and pair_count_matches_declared
        and max_degree is not None
        and max_degree <= 4
        and target_count == 32
        and all_excluded
        and survivors_empty
    )


def target_cases() -> list[TargetCase]:
    return [TargetCase(m, b) for m in range(49, 57) for b in TARGET_B_VALUES]


def load_covering(path: str | Path) -> tuple[dict[str, Any], list[Pair]]:
    with Path(path).open("r", encoding="ascii") as handle:
        raw = json.load(handle)
    pairs = [
        Pair(
            index=i,
            base_complexity=int(item["base_complexity"]),
            degree=int(item["degree"]),
            tree=tree_key(item["tree"]),
        )
        for i, item in enumerate(raw["pairs"])
    ]
    return raw, pairs


class ExactSolver:
    def __init__(self, max_solutions: int = 20):
        self.max_solutions = max_solutions

    def solve_pair(self, pair: Pair, case: TargetCase) -> list[Representation]:
        if pair.base_complexity > case.complexity_bound:
            return []
        results: list[Representation] = []
        n = case.n
        max_e = v_p(n, 3)
        for e in range(max_e + 1):
            budget = (case.complexity_bound - pair.base_complexity) // 3 - e
            if budget < 0:
                continue
            target = n // (3**e)
            for exponents in self.solve_tree(pair.tree, target, budget):
                complexity = pair.base_complexity + 3 * (e + sum(exponents))
                if complexity <= case.complexity_bound:
                    assert evaluate(pair.tree, exponents) * (3**e) == n
                    results.append(
                        Representation(
                            pair_index=pair.index,
                            e=e,
                            exponents=exponents,
                            complexity=complexity,
                            polynomial=pretty(pair.tree),
                        )
                    )
                    if len(results) >= self.max_solutions:
                        return results
        return results

    @lru_cache(maxsize=None)
    def solve_tree(self, key: TreeKey, target: int, budget: int) -> tuple[tuple[int, ...], ...]:
        if target <= 0 or budget < 0:
            return ()
        if not value_in_budget_range(key, target, budget):
            return ()
        if key[0] == "A":
            return self._solve_affine(key, target, budget)
        return self._solve_product(key, target, budget)

    def _solve_affine(self, key: TreeKey, target: int, budget: int) -> tuple[tuple[int, ...], ...]:
        constant = int(key[1])
        child = key[2]
        diff = target - constant
        if diff <= 0:
            return ()
        limit = min(v_p(diff, 3), budget)
        found: list[tuple[int, ...]] = []
        power = 1
        for exponent in range(limit + 1):
            if diff % power == 0:
                child_target = diff // power
                child_budget = budget - exponent
                if not value_in_budget_range(child, child_target, child_budget):
                    power *= 3
                    continue
                for child_exponents in self.solve_tree(child, child_target, child_budget):
                    found.append((exponent,) + child_exponents)
            power *= 3
        return tuple(found)

    def _solve_product(self, key: TreeKey, target: int, budget: int) -> tuple[tuple[int, ...], ...]:
        constant = int(key[1])
        children = key[2]
        if target % constant != 0:
            return ()
        rem = target // constant
        if not children:
            return ((),) if rem == 1 else ()
        return self._solve_product_children(children, rem, budget)

    def _solve_product_children(
        self, children: tuple[TreeKey, ...], target: int, budget: int
    ) -> tuple[tuple[int, ...], ...]:
        if not children:
            return ((),) if target == 1 else ()
        first, rest = children[0], children[1:]
        found: list[tuple[int, ...]] = []
        first_min = min_value(first)
        for divisor in divisors(target):
            if divisor < first_min:
                continue
            if not value_in_budget_range(first, divisor, budget):
                continue
            for first_exponents in self.solve_tree(first, divisor, budget):
                used = sum(first_exponents)
                if used > budget:
                    continue
                rest_target = target // divisor
                rest_budget = budget - used
                if not children_value_in_budget_range(rest, rest_target, rest_budget):
                    continue
                for rest_exponents in self._solve_product_children(rest, rest_target, budget - used):
                    found.append(first_exponents + rest_exponents)
        return tuple(found)


def verify_covering(
    covering_path: str | Path,
    required_threshold: int = 46,
    max_solutions_per_case: int = 20,
) -> dict[str, Any]:
    raw, pairs = load_covering(covering_path)
    threshold = int(raw.get("threshold_multiple", -1))
    if threshold != required_threshold:
        raise ValueError(f"expected S_{required_threshold}, got S_{threshold}")

    solver = ExactSolver(max_solutions=max_solutions_per_case)
    cases: list[dict[str, Any]] = []
    all_excluded = True

    for case in target_cases():
        survivors: list[Representation] = []
        for pair in pairs:
            survivors.extend(solver.solve_pair(pair, case))
            if len(survivors) >= max_solutions_per_case:
                break
        excluded = not survivors
        all_excluded = all_excluded and excluded
        cases.append(
            {
                "m": case.m,
                "b": case.b,
                "N": case.n,
                "complexity_bound": case.complexity_bound,
                "excluded": excluded,
                "survivors": [representation_to_json(r) for r in survivors],
            }
        )

    degrees = [pair.degree for pair in pairs]
    max_degree = max(degrees) if degrees else None
    degree_histogram = {str(d): degrees.count(d) for d in sorted(set(degrees))}
    target_count = len(cases)
    survivors_empty = all(not case["survivors"] for case in cases)
    declared_pair_count = raw.get("pair_count")
    pair_count_matches_declared = declared_pair_count is None or int(declared_pair_count) == len(pairs)
    certificate_succeeded = certificate_success_conditions(
        threshold=threshold,
        pair_count_matches_declared=pair_count_matches_declared,
        max_degree=max_degree,
        target_count=target_count,
        all_excluded=all_excluded,
        survivors_empty=survivors_empty,
    )
    return {
        "covering_path": str(covering_path),
        "threshold_multiple": threshold,
        "declared_pair_count": declared_pair_count,
        "pair_count": len(pairs),
        "pair_count_matches_declared": pair_count_matches_declared,
        "max_degree": max_degree,
        "degree_histogram": degree_histogram,
        "target_count": target_count,
        "all_excluded": all_excluded,
        "survivors_empty": survivors_empty,
        "certificate_succeeded": certificate_succeeded,
        "cases": cases,
    }


def representation_to_json(representation: Representation) -> dict[str, Any]:
    return {
        "pair_index": representation.pair_index,
        "e": representation.e,
        "k": list(representation.exponents),
        "complexity": representation.complexity,
        "polynomial": representation.polynomial,
    }


@lru_cache(maxsize=None)
def min_value(key: TreeKey) -> int:
    return sum_coefficients(key)


@lru_cache(maxsize=None)
def max_value_for_budget(key: TreeKey, budget: int) -> int:
    if budget < 0:
        return 0
    return max_coefficient(key) * term_count(key) * (3**budget)


def value_in_budget_range(key: TreeKey, target: int, budget: int) -> bool:
    return min_value(key) <= target <= max_value_for_budget(key, budget)


@lru_cache(maxsize=None)
def children_min_value(children: tuple[TreeKey, ...]) -> int:
    return product(min_value(child) for child in children)


@lru_cache(maxsize=None)
def children_max_value_for_budget(children: tuple[TreeKey, ...], budget: int) -> int:
    if budget < 0:
        return 0
    return product(max_value_for_budget(child, budget) for child in children)


def children_value_in_budget_range(
    children: tuple[TreeKey, ...], target: int, budget: int
) -> bool:
    return children_min_value(children) <= target <= children_max_value_for_budget(children, budget)
