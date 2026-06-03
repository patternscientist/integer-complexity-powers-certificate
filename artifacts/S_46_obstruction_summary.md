# S_46 Obstruction Summary

This is a structural analysis of the existing S_46 near-power certificate.
It does not change the verifier, the certificate logic, or the mathematical target.

## Headline

- Covering: `artifacts\S_46.json`
- Threshold multiple: `46`
- Pairs parsed: `2284637`
- Pair-target combinations classified: `73108384`
- Max degree: `4`
- Survivors found by analyzer: `0`
- Hard cases needing bounded exponent enumeration: `258136`
- Hard case records written: `258136`

## Classification Order

- `cost_bound_impossible`: base complexity C exceeds 2m-2
- `degree_max_exponent_bound_impossible`: degree zero or zero exponent budget leaves no exact exponent freedom compatible with N
- `size_interval_impossible`: for every allowed top exponent e, N/3^e is outside the exact min and coefficient-sum upper interval for the remaining budget
- `v_3_obstruction`: residue sets modulo 3^5 show that no allowed assignment can have the required 3-adic valuation
- `modular_obstruction`: residue sets modulo the first failing small modulus among 16,64,81,243 exclude N/3^e for every allowed e
- `factorization_obstruction`: root product constant divisibility excludes every allowed top exponent after earlier filters
- `exhaustive_exponent_enumeration_needed`: earlier exact filters did not exclude the pair-target; the existing verifier's exact exponent enumeration is the remaining exclusion mechanism. The analyzer records the exact bounded exponent-tuple search-space size without re-evaluating every tuple.

## Obstruction Counts

| Obstruction | Count |
| --- | ---: |
| `modular_obstruction` | 32538546 |
| `degree_max_exponent_bound_impossible` | 22705148 |
| `size_interval_impossible` | 17250000 |
| `exhaustive_exponent_enumeration_needed` | 258136 |
| `v_3_obstruction` | 230525 |
| `factorization_obstruction` | 125225 |
| `cost_bound_impossible` | 804 |

## By Degree

### Degree 0

| Obstruction | Count |
| --- | ---: |
| `degree_max_exponent_bound_impossible` | 22705148 |
| `cost_bound_impossible` | 804 |

### Degree 1

| Obstruction | Count |
| --- | ---: |
| `size_interval_impossible` | 15250548 |
| `modular_obstruction` | 13460678 |
| `v_3_obstruction` | 200504 |
| `factorization_obstruction` | 16109 |
| `exhaustive_exponent_enumeration_needed` | 9377 |

### Degree 2

| Obstruction | Count |
| --- | ---: |
| `modular_obstruction` | 14060359 |
| `size_interval_impossible` | 1999452 |
| `exhaustive_exponent_enumeration_needed` | 86382 |
| `factorization_obstruction` | 66572 |
| `v_3_obstruction` | 26595 |

### Degree 3

| Obstruction | Count |
| --- | ---: |
| `modular_obstruction` | 4591142 |
| `exhaustive_exponent_enumeration_needed` | 121809 |
| `factorization_obstruction` | 39847 |
| `v_3_obstruction` | 3426 |

### Degree 4

| Obstruction | Count |
| --- | ---: |
| `modular_obstruction` | 426367 |
| `exhaustive_exponent_enumeration_needed` | 40568 |
| `factorization_obstruction` | 2697 |

## Base Complexity Buckets

The JSON report contains the full obstruction matrix by base-complexity bucket.

| C bucket | Total pair-targets | Dominant obstruction | Dominant count |
| --- | ---: | --- | ---: |
| `C000_009` | 6656 | `modular_obstruction` | 5853 |
| `C010_019` | 644352 | `modular_obstruction` | 584334 |
| `C020_029` | 6584608 | `modular_obstruction` | 5796381 |
| `C030_039` | 20958784 | `modular_obstruction` | 14058786 |
| `C040_049` | 25757760 | `modular_obstruction` | 9704324 |
| `C050_059` | 14103008 | `degree_max_exponent_bound_impossible` | 8755968 |
| `C060_069` | 4112544 | `degree_max_exponent_bound_impossible` | 3726432 |
| `C070_079` | 811104 | `degree_max_exponent_bound_impossible` | 805888 |
| `C080_089` | 117952 | `degree_max_exponent_bound_impossible` | 117536 |
| `C090_099` | 10208 | `degree_max_exponent_bound_impossible` | 10060 |
| `C100_109` | 1408 | `degree_max_exponent_bound_impossible` | 752 |

## Target Breakdown

The JSON report contains the full obstruction matrix for every `(m,b)` target.

| Target | Total pair-targets | Dominant obstruction | Dominant count | Hard cases |
| --- | ---: | --- | ---: | ---: |
| `m49_b1` | 2284637 | `modular_obstruction` | 867597 | 6503 |
| `m49_b6` | 2284637 | `modular_obstruction` | 868947 | 3525 |
| `m49_b8` | 2284637 | `modular_obstruction` | 856576 | 16724 |
| `m49_b9` | 2284637 | `modular_obstruction` | 872373 | 2868 |
| `m50_b1` | 2284637 | `modular_obstruction` | 919564 | 6673 |
| `m50_b6` | 2284637 | `modular_obstruction` | 915615 | 4125 |
| `m50_b8` | 2284637 | `modular_obstruction` | 908869 | 6733 |
| `m50_b9` | 2284637 | `modular_obstruction` | 918121 | 3653 |
| `m51_b1` | 2284637 | `modular_obstruction` | 944543 | 3938 |
| `m51_b6` | 2284637 | `modular_obstruction` | 939629 | 6446 |
| `m51_b8` | 2284637 | `modular_obstruction` | 935024 | 18548 |
| `m51_b9` | 2284637 | `modular_obstruction` | 947131 | 1103 |
| `m52_b1` | 2284637 | `modular_obstruction` | 950700 | 5245 |
| `m52_b6` | 2284637 | `modular_obstruction` | 933525 | 13278 |
| `m52_b8` | 2284637 | `modular_obstruction` | 935894 | 8612 |
| `m52_b9` | 2284637 | `modular_obstruction` | 944716 | 3672 |
| `m53_b1` | 2284637 | `modular_obstruction` | 1019724 | 2989 |
| `m53_b6` | 2284637 | `modular_obstruction` | 1016743 | 4570 |
| `m53_b8` | 2284637 | `modular_obstruction` | 1006427 | 15110 |
| `m53_b9` | 2284637 | `modular_obstruction` | 1019678 | 1892 |
| `m54_b1` | 2284637 | `modular_obstruction` | 1075641 | 17360 |
| `m54_b6` | 2284637 | `modular_obstruction` | 1077701 | 6887 |
| `m54_b8` | 2284637 | `modular_obstruction` | 1067170 | 13022 |
| `m54_b9` | 2284637 | `modular_obstruction` | 1078879 | 6886 |
| `m55_b1` | 2284637 | `modular_obstruction` | 1123414 | 19398 |
| `m55_b6` | 2284637 | `modular_obstruction` | 1137486 | 3405 |
| `m55_b8` | 2284637 | `modular_obstruction` | 1133373 | 12929 |
| `m55_b9` | 2284637 | `modular_obstruction` | 1141723 | 1734 |
| `m56_b1` | 2284637 | `modular_obstruction` | 1235329 | 27461 |
| `m56_b6` | 2284637 | `modular_obstruction` | 1249807 | 4090 |
| `m56_b8` | 2284637 | `modular_obstruction` | 1244245 | 5632 |
| `m56_b9` | 2284637 | `modular_obstruction` | 1252382 | 3125 |

## Modular Details

| First failing modulus | Count |
| --- | ---: |
| `mod_16` | 29562452 |
| `mod_81` | 1959400 |
| `mod_64` | 709643 |
| `mod_243` | 307051 |

## Top Polynomial Shapes

| Shape signature | Total pair-targets |
| --- | ---: |
| `D1:P(A(P0))` | 26126208 |
| `D0:P0` | 22705952 |
| `D2:P(A(P(A(P0))))` | 8060896 |
| `D2:P(A(P0)*A(P0))` | 4790592 |
| `D1:A(P0)` | 2811008 |
| `D2:A(P(A(P0)))` | 1925984 |
| `D2:P(A(A(P0)))` | 1271040 |
| `D3:P(A(P(A(P(A(P0))))))` | 981536 |
| `D3:P(A(P0)*A(P(A(P0))))` | 699296 |
| `D3:P(A(P(A(P0)*A(P0))))` | 630048 |
| `D3:P(A(P(A(P0)))*A(P0))` | 521984 |
| `D3:A(P(A(P(A(P0)))))` | 341024 |
| `D3:P(A(A(P0))*A(P0))` | 313760 |
| `D3:P(A(P0)*A(P0)*A(P0))` | 288640 |
| `D3:P(A(A(P(A(P0)))))` | 287808 |
| `D3:P(A(P(A(A(P0)))))` | 265632 |
| `D3:A(P(A(P0)*A(P0)))` | 206912 |
| `D2:A(A(P0))` | 190848 |
| `D3:A(A(P(A(P0))))` | 81152 |
| `D3:A(P(A(A(P0))))` | 72672 |
| `D3:P(A(A(A(P0))))` | 55616 |
| `D4:P(A(P0)*A(P(A(P(A(P0))))))` | 25920 |
| `D4:P(A(P(A(P(A(P(A(P0))))))))` | 22272 |
| `D4:P(A(A(P(A(P0))))*A(P0))` | 22240 |
| `D4:P(A(P(A(P0)*A(P0)))*A(P0))` | 20480 |
| `D4:P(A(P(A(P0)*A(P(A(P0))))))` | 19872 |
| `D4:P(A(A(P0))*A(P(A(P0))))` | 18976 |
| `D4:A(P(A(P(A(P(A(P0)))))))` | 17600 |
| `D4:P(A(P(A(P0)))*A(P(A(P0))))` | 17600 |
| `D4:P(A(P(A(P(A(P0)*A(P0))))))` | 15936 |

## Hard Cases

Hard cases are written to `artifacts/S_46_hard_cases.json`. Each record includes the polynomial, base complexity, target, exponent-sum bound, and exact bounded exponent-tuple search-space size. Closest misses are only populated when a run explicitly evaluates tuples.


