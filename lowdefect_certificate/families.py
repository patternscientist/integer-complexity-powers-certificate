"""Exact evaluators for exported Altman low-defect families."""

from __future__ import annotations

from functools import lru_cache, reduce
from operator import mul
from typing import Any, Iterable, Sequence

TreeKey = tuple[Any, ...]


def tree_key(tree: dict[str, Any]) -> TreeKey:
    kind = tree["kind"]
    if kind == "affine":
        return ("A", int(tree["constant"]), tree_key(tree["child"]))
    if kind == "product":
        return (
            "M",
            int(tree["constant"]),
            tuple(tree_key(child) for child in tree.get("children", [])),
        )
    raise ValueError(f"unknown tree kind: {kind}")


@lru_cache(maxsize=None)
def degree(key: TreeKey) -> int:
    if key[0] == "A":
        return 1 + degree(key[2])
    return sum(degree(child) for child in key[2])


@lru_cache(maxsize=None)
def leading_coefficient(key: TreeKey) -> int:
    if key[0] == "A":
        return leading_coefficient(key[2])
    return int(key[1]) * product(leading_coefficient(child) for child in key[2])


@lru_cache(maxsize=None)
def term_count(key: TreeKey) -> int:
    if key[0] == "A":
        return term_count(key[2]) + 1
    return product(term_count(child) for child in key[2])


@lru_cache(maxsize=None)
def max_coefficient(key: TreeKey) -> int:
    if key[0] == "A":
        return max(int(key[1]), max_coefficient(key[2]))
    return int(key[1]) * product(max_coefficient(child) for child in key[2])


@lru_cache(maxsize=None)
def sum_coefficients(key: TreeKey) -> int:
    if key[0] == "A":
        return int(key[1]) + sum_coefficients(key[2])
    return int(key[1]) * product(sum_coefficients(child) for child in key[2])


def evaluate(key: TreeKey, exponents: Sequence[int]) -> int:
    value, used = _evaluate_prefix(key, exponents)
    if used != len(exponents):
        raise ValueError("too many exponents supplied")
    return value


def _evaluate_prefix(key: TreeKey, exponents: Sequence[int]) -> tuple[int, int]:
    if key[0] == "A":
        if not exponents:
            raise ValueError("too few exponents supplied")
        child_value, used = _evaluate_prefix(key[2], exponents[1:])
        return child_value * (3 ** int(exponents[0])) + int(key[1]), used + 1

    offset = 0
    value = int(key[1])
    for child in key[2]:
        child_value, used = _evaluate_prefix(child, exponents[offset:])
        value *= child_value
        offset += used
    return value, offset


def pretty(key: TreeKey) -> str:
    if key[0] == "A":
        return f"({pretty(key[2])})3^_+{key[1]}"
    constant = "" if int(key[1]) == 1 and key[2] else str(key[1])
    return constant + "".join(f"({pretty(child)})" for child in key[2])


def product(values: Iterable[int]) -> int:
    return reduce(mul, values, 1)
