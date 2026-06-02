"""Small exact integer-complexity helpers used by tests."""

from __future__ import annotations

from dataclasses import dataclass


def largest_with_complexity_at_most(cost: int) -> int:
    """Altman's E(cost): the largest value obtainable with at most cost ones."""

    if cost < 1:
        return 0
    q, r = divmod(cost, 3)
    if r == 0:
        return 3**q
    if r == 1:
        return 4 * 3 ** (q - 1)
    return 2 * 3**q


@dataclass(frozen=True)
class ComplexityTable:
    costs: dict[int, int]
    preferred_root: dict[int, str]


def build_complexity_table(max_cost: int) -> ComplexityTable:
    """Build exact complexities through E(max_cost), preferring + on ties."""

    max_value = largest_with_complexity_at_most(max_cost)
    costs: dict[int, int] = {1: 1}
    roots: dict[int, str] = {1: "1"}
    layers: dict[int, list[int]] = {1: [1]}

    def record(value: int, cost: int, root: str) -> None:
        if value > max_value:
            return
        old = costs.get(value)
        if old is None or cost < old or (cost == old and root == "+" and roots[value] == "*"):
            costs[value] = cost
            roots[value] = root

    for cost in range(2, max_cost + 1):
        for left_cost in range(1, cost // 2 + 1):
            right_cost = cost - left_cost
            for left in layers.get(left_cost, []):
                for right in layers.get(right_cost, []):
                    if left_cost == right_cost and right < left:
                        continue
                    record(left + right, cost, "+")
                    if left != 1 and right != 1:
                        record(left * right, cost, "*")
        layers[cost] = sorted(n for n, c in costs.items() if c == cost)

    return ComplexityTable(costs=costs, preferred_root=roots)


def solid_numbers_up_to_complexity(max_cost: int) -> list[int]:
    """Return solid/chunk numbers with complexity at most max_cost.

    Altman's implementation calls these "chunks" and detects them by checking
    whether the preferred shortest expression has root 1 or * rather than +.
    """

    table = build_complexity_table(max_cost)
    return sorted(
        n
        for n, cost in table.costs.items()
        if cost <= max_cost and table.preferred_root[n] != "+"
    )

