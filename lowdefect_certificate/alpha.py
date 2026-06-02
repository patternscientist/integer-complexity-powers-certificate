"""Exact comparisons involving alpha = delta(2) = 2 - 3 log_3(2)."""

from __future__ import annotations


def compare_alpha_multiple_to_int(k: int, n: int) -> int:
    """Compare k * alpha with the integer n exactly.

    Since alpha = 2 - 3 log_3(2),

        k alpha < n

    is equivalent to

        3 ** (2k - n) < 2 ** (3k).

    The equality case cannot occur for positive k because it would equate a
    power of 3 with a power of 2.
    """

    if k < 0:
        raise ValueError("k must be nonnegative")
    exponent = 2 * k - n
    rhs = 2 ** (3 * k)
    if exponent < 0:
        return -1
    lhs = 3**exponent
    return (lhs > rhs) - (lhs < rhs)


def alpha_multiple_less_than(k: int, n: int) -> bool:
    return compare_alpha_multiple_to_int(k, n) < 0


def floor_alpha_multiple(k: int) -> int:
    """Return floor(k * alpha) using only exact integer comparisons."""

    if k < 0:
        raise ValueError("k must be nonnegative")
    n = 0
    while compare_alpha_multiple_to_int(k, n + 1) >= 0:
        n += 1
    return n

