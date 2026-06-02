"""Deterministic integer factorization for certificate-sized inputs."""

from __future__ import annotations

from collections import Counter
from functools import lru_cache
from math import gcd


def v_p(n: int, p: int) -> int:
    count = 0
    while n and n % p == 0:
        n //= p
        count += 1
    return count


def is_power_of(n: int, base: int) -> int | None:
    if n < 1:
        return None
    exponent = 0
    while n % base == 0:
        n //= base
        exponent += 1
    return exponent if n == 1 else None


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    small_primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for p in small_primes:
        if n % p == 0:
            return n == p
    d = n - 1
    s = 0
    while d % 2 == 0:
        s += 1
        d //= 2
    for a in small_primes:
        if a >= n:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = (x * x) % n
            if x == n - 1:
                break
        else:
            return False
    return True


def pollard_rho(n: int) -> int:
    if n % 2 == 0:
        return 2
    if n % 3 == 0:
        return 3
    c = 1
    while True:
        x = 2
        y = 2
        d = 1
        while d == 1:
            x = (x * x + c) % n
            y = (y * y + c) % n
            y = (y * y + c) % n
            d = gcd(abs(x - y), n)
        if d != n:
            return d
        c += 1


@lru_cache(maxsize=None)
def factor_tuple(n: int) -> tuple[tuple[int, int], ...]:
    if n < 1:
        raise ValueError("can only factor positive integers")
    factors: Counter[int] = Counter()

    def rec(m: int) -> None:
        if m == 1:
            return
        if is_prime(m):
            factors[m] += 1
            return
        d = pollard_rho(m)
        rec(d)
        rec(m // d)

    rec(n)
    return tuple(sorted(factors.items()))


@lru_cache(maxsize=None)
def divisors(n: int) -> tuple[int, ...]:
    result = [1]
    for prime, exponent in factor_tuple(n):
        powers = [prime**e for e in range(exponent + 1)]
        result = [d * p for d in result for p in powers]
    return tuple(sorted(result))

