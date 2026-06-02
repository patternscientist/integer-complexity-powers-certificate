# Reduction Note

This note records the exact implication certified by this repository.

## Statement

For positive exponents, the following inputs imply

```text
||2^m|| = 2m for 1 <= m <= 56.
```

Inputs:

1. The public theorem

   ```text
   ||2^k 3^l|| = 2k + 3l for k <= 48
   ```

   in particular with `l = 0`.

2. The certified exclusions

   ```text
   ||2^m - b|| >= 2m - 1
   ```

   for every

   ```text
   49 <= m <= 56
   b in {1, 6, 8, 9}.
   ```

3. The low-defect/root-addition reduction used by the certificate:
   if a first counterexample to Selfridge for powers of two occurs in
   `49 <= m <= 56`, then it has a final additive split

   ```text
   2^m = (2^m - b) + b
   ```

   where `b` is solid, `||b|| <= 6`, and therefore

   ```text
   b in {1, 6, 8, 9}.
   ```

## Proof Of The Implication

The upper bound is immediate for every positive `m`:

```text
||2^m|| <= 2m,
```

by writing `2^m` as the product of `m` copies of `(1+1)`.

For `1 <= m <= 48`, the public theorem with `l = 0` gives

```text
||2^m|| = 2m.
```

It remains to rule out `49 <= m <= 56`.

Assume, for contradiction, that there is a counterexample with
`49 <= m <= 56`. Choose the least such `m`. Since complexity is
integer-valued and `||2^m|| < 2m`, we have

```text
||2^m|| <= 2m - 1.
```

By the reduction, the first counterexample has a final additive split

```text
2^m = (2^m - b) + b
```

with

```text
b in {1, 6, 8, 9}.
```

The cost of this final addition is the cost of an expression for `2^m - b`
plus the cost of an expression for `b`. Since every positive integer has
complexity at least `1`,

```text
||2^m - b|| + ||b|| <= 2m - 1
```

implies

```text
||2^m - b|| <= 2m - 2.
```

This contradicts the certified exclusion

```text
||2^m - b|| >= 2m - 1.
```

Therefore no first counterexample exists in `49 <= m <= 56`. Together with
the public theorem for `m <= 48` and the elementary upper bound, this proves
the stated implication for positive `m <= 56`.

## Scope

This note does not independently prove the public `k <= 48` theorem or the
low-defect/root-addition reduction. It records how those inputs combine with
the generated `S_46` certificate in this repository.

