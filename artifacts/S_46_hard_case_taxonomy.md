# S_46 Hard-Case Taxonomy

Exploratory proof-mining report. This does not alter the certificate verifier and does not claim a theorem.

## Headline

- Hard cases: `258136`
- Closest-miss samples evaluated exactly: `53`

## Equation Classes

| Class | Count |
| --- | ---: |
| `bilinear` | 86382 |
| `higher_multilinear` | 162377 |
| `linear` | 9377 |

## Top 20 Hard-Case Shape Signatures

| Rank | Shape | Count | Median B | Median tuples | Class counts |
| ---: | --- | ---: | ---: | ---: | --- |
| 1 | `P(A(P0)*A(P0))` | 36561 | 23 | 435 | `{'bilinear': 36561}` |
| 2 | `A(P(A(P0)))` | 31079 | 24 | 465 | `{'bilinear': 31079}` |
| 3 | `P(A(P0)*A(P(A(P0))))` | 23552 | 25.0 | 4495.0 | `{'higher_multilinear': 23552}` |
| 4 | `P(A(P(A(P0)))*A(P0))` | 19157 | 26 | 4495 | `{'higher_multilinear': 19157}` |
| 5 | `P(A(A(P0))*A(P0))` | 12919 | 26 | 4495 | `{'higher_multilinear': 12919}` |
| 6 | `A(P(A(P(A(P0)))))` | 12861 | 26 | 4960 | `{'higher_multilinear': 12861}` |
| 7 | `P(A(P(A(P0))))` | 12740 | 23.0 | 484.0 | `{'bilinear': 12740}` |
| 8 | `A(P(A(P0)*A(P0)))` | 12309 | 26 | 4900 | `{'higher_multilinear': 12309}` |
| 9 | `P(A(P0)*A(P0)*A(P0))` | 11690 | 25.0 | 4495.0 | `{'higher_multilinear': 11690}` |
| 10 | `P(A(P(A(P0)*A(P0))))` | 7140 | 25.0 | 4324.0 | `{'higher_multilinear': 7140}` |
| 11 | `A(P0)` | 6784 | 22.0 | 26.0 | `{'linear': 6784}` |
| 12 | `P(A(P(A(P(A(P0))))))` | 5866 | 25.0 | 4900.0 | `{'higher_multilinear': 5866}` |
| 13 | `A(A(P(A(P0))))` | 5541 | 26 | 4060 | `{'higher_multilinear': 5541}` |
| 14 | `P(A(A(P(A(P0)))))` | 3770 | 25.0 | 4900.0 | `{'higher_multilinear': 3770}` |
| 15 | `A(A(P0))` | 3724 | 24.0 | 400.0 | `{'bilinear': 3724}` |
| 16 | `A(P(A(A(P0))))` | 3373 | 27 | 5525 | `{'higher_multilinear': 3373}` |
| 17 | `P(A(A(P0))*A(P(A(P0))))` | 3056 | 28.0 | 40920.0 | `{'higher_multilinear': 3056}` |
| 18 | `P(A(P(A(P0)*A(P0)))*A(P0))` | 2703 | 28 | 40920 | `{'higher_multilinear': 2703}` |
| 19 | `P(A(A(P(A(P0))))*A(P0))` | 2634 | 28.0 | 44226.0 | `{'higher_multilinear': 2634}` |
| 20 | `P(A(P0))` | 2593 | 22 | 43 | `{'linear': 2593}` |

## Top 20 Largest Exponent Search Spaces

| Rank | Pair | Target | Degree | B | Tuples | Shape |
| ---: | ---: | --- | ---: | ---: | ---: | --- |
| 1 | 0 | `m=54, b=1` | 4 | 33 | 264606 | `A(A(A(A(P0))))` |
| 2 | 4 | `m=54, b=1` | 4 | 32 | 234521 | `A(A(A(A(P0))))` |
| 3 | 18 | `m=54, b=1` | 4 | 32 | 234521 | `A(A(A(P(A(P0)))))` |
| 4 | 37 | `m=54, b=1` | 4 | 32 | 234521 | `A(A(A(P(A(P0)))))` |
| 5 | 463 | `m=54, b=1` | 4 | 32 | 234521 | `A(A(P(A(P0)*A(P0))))` |
| 6 | 464 | `m=54, b=1` | 4 | 32 | 234521 | `A(A(P(A(P0)*A(P0))))` |
| 7 | 9389 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(A(P0)))))` |
| 8 | 9402 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(P0))*A(P0)))` |
| 9 | 9432 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(P0))*A(P0)))` |
| 10 | 9434 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(P0))*A(P0)))` |
| 11 | 14801 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(A(P0)))))` |
| 12 | 14802 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(A(P0)))))` |
| 13 | 14803 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(A(P0)))))` |
| 14 | 14854 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(A(P(A(P0))))))` |
| 15 | 16125 | `m=54, b=1` | 4 | 32 | 234521 | `A(P(A(P(A(A(P0))))))` |
| 16 | 179384 | `m=54, b=1` | 4 | 32 | 234521 | `P(A(A(A(P0)))*A(P0))` |
| 17 | 179396 | `m=54, b=1` | 4 | 32 | 234521 | `P(A(A(A(P0)))*A(P0))` |
| 18 | 179445 | `m=54, b=1` | 4 | 32 | 234521 | `P(A(A(P0))*A(A(P0)))` |
| 19 | 190502 | `m=54, b=1` | 4 | 32 | 234521 | `P(A(P0)*A(P(A(A(P0)))))` |
| 20 | 22 | `m=54, b=1` | 4 | 31 | 207081 | `A(A(A(P(A(P0)))))` |

## Stronger Modulus Experiment

| Category | Count |
| --- | ---: |
| `killed_by_256_only` | 6214 |
| `killed_by_729_only` | 111409 |
| `killed_by_both_256_and_729` | 7398 |
| `survives_256_and_729` | 133115 |

| Modulus | Killed | Target possible | Median image size | Median witness e count |
| ---: | ---: | ---: | ---: | ---: |
| 16 | 0 | 258136 | 3.0 | 1.0 |
| 64 | 0 | 258136 | 12.0 | 1.0 |
| 81 | 0 | 258136 | 26.0 | 1.0 |
| 243 | 0 | 258136 | 49.0 | 1.0 |
| 256 | 13612 | 244524 | 48.0 | 1.0 |
| 729 | 118807 | 139329 | 78.0 | 1.0 |

## Proposed Hard-Core Normal Forms

- `NF1`: shape `P(A(P0)*A(P0))`, class `bilinear`, count `36561`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF2`: shape `A(P(A(P0)))`, class `bilinear`, count `31079`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF3`: shape `P(A(P0)*A(P(A(P0))))`, class `higher_multilinear`, count `23552`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF4`: shape `P(A(P(A(P0)))*A(P0))`, class `higher_multilinear`, count `19157`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF5`: shape `P(A(A(P0))*A(P0))`, class `higher_multilinear`, count `12919`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF6`: shape `A(P(A(P(A(P0)))))`, class `higher_multilinear`, count `12861`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF7`: shape `P(A(P(A(P0))))`, class `bilinear`, count `12740`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF8`: shape `A(P(A(P0)*A(P0)))`, class `higher_multilinear`, count `12309`. Candidate hard-core family; inspect whether a uniform congruence, divisibility, or monotone gap argument can replace explicit exponent enumeration.
- `NF9`: shape `modulus-upgrade residual`, class `mixed`, count `133115`. Cases surviving both mod 256 and mod 729 are the natural residual hard core after the first stronger-modulus experiment.

## Closest-Miss Sampling

The hard-case file contains 258,136 cases. This exploratory run evaluates exact closest misses for the union of the 20 largest search spaces, one representative from each top-20 shape signature, and one representative from each degree/b stratum.

| Pair | Target | Degree | B | Tuples evaluated | Signed gap | Gap pattern |
| ---: | --- | ---: | ---: | ---: | ---: | --- |
| 0 | `m=54, b=1` | 4 | 33 | 264606 | 1336369392046122 | `v2=1, v3=1, mod16=10, mod81=78` |
| 4 | `m=54, b=1` | 4 | 32 | 234521 | 5042409511311936 | `v2=6, v3=5, mod16=0, mod81=0` |
| 18 | `m=54, b=1` | 4 | 32 | 234521 | 1334674556389368 | `v2=3, v3=5, mod16=8, mod81=0` |
| 37 | `m=54, b=1` | 4 | 32 | 234521 | 3188542033850652 | `v2=2, v3=5, mod16=12, mod81=0` |
| 463 | `m=54, b=1` | 4 | 32 | 234521 | -4224103236085240 | `v2=3, v3=0, mod16=8, mod81=1` |
| 464 | `m=54, b=1` | 4 | 32 | 234521 | -515803379036434 | `v2=1, v3=0, mod16=2, mod81=7` |
| 9389 | `m=54, b=1` | 4 | 32 | 234521 | 1334673781194096 | `v2=4, v3=5, mod16=0, mod81=0` |
| 9402 | `m=54, b=1` | 4 | 32 | 234521 | -515803809503668 | `v2=2, v3=0, mod16=4, mod81=31` |
| 9432 | `m=54, b=1` | 4 | 32 | 234521 | 3190235448984894 | `v2=1, v3=4, mod16=14, mod81=0` |
| 9434 | `m=54, b=1` | 4 | 32 | 234521 | -104021430523084 | `v2=2, v3=0, mod16=12, mod81=1` |
| 14801 | `m=54, b=1` | 4 | 32 | 234521 | 6894582023956698 | `v2=1, v3=5, mod16=10, mod81=0` |
| 14802 | `m=54, b=1` | 4 | 32 | 234521 | -4223538592278690 | `v2=1, v3=1, mod16=2, mod81=3` |
| 14803 | `m=54, b=1` | 4 | 32 | 234521 | 3188541646253016 | `v2=3, v3=5, mod16=8, mod81=0` |
| 14854 | `m=54, b=1` | 4 | 32 | 234521 | 3186847069034130 | `v2=1, v3=5, mod16=2, mod81=0` |
| 16125 | `m=54, b=1` | 4 | 32 | 234521 | 3186846294193152 | `v2=10, v3=5, mod16=0, mod81=0` |
| 179384 | `m=54, b=1` | 4 | 32 | 234521 | -378542624306728 | `v2=3, v3=0, mod16=8, mod81=67` |
| 179396 | `m=54, b=1` | 4 | 32 | 234521 | 719323734953376 | `v2=5, v3=6, mod16=0, mod81=0` |
| 179445 | `m=54, b=1` | 4 | 32 | 234521 | 650902145325678 | `v2=1, v3=5, mod16=14, mod81=0` |
| 190502 | `m=54, b=1` | 4 | 32 | 234521 | -241281869577028 | `v2=2, v3=0, mod16=4, mod81=52` |
| 22 | `m=54, b=1` | 4 | 31 | 207081 | 5042409769710414 | `v2=1, v3=3, mod16=14, mod81=54` |
| 1445 | `m=54, b=1` | 3 | 32 | 27440 | -515960284865922 | `v2=1, v3=2, mod16=2, mod81=9` |
| 2544 | `m=54, b=1` | 2 | 29 | 2035 | -1545259053858580 | `v2=2, v3=0, mod16=4, mod81=1` |
| 14863 | `m=54, b=1` | 3 | 32 | 27440 | 3190174235485146 | `v2=1, v3=2, mod16=10, mod81=72` |
| 16523 | `m=54, b=1` | 3 | 32 | 27440 | 3189985949127492 | `v2=2, v3=2, mod16=4, mod81=72` |
| 16693 | `m=54, b=1` | 2 | 32 | 2485 | -515803465129870 | `v2=1, v3=0, mod16=14, mod81=1` |
| 9746 | `m=54, b=1` | 3 | 32 | 27440 | -515803465129870 | `v2=1, v3=0, mod16=14, mod81=1` |
| 58513 | `m=54, b=1` | 1 | 29 | 140 | 5111887564883898 | `v2=1, v3=5, mod16=10, mod81=0` |
| 518348 | `m=54, b=1` | 3 | 30 | 22625 | 719323742393928 | `v2=3, v3=3, mod16=8, mod81=54` |
| 179821 | `m=54, b=1` | 4 | 31 | 207081 | 719323742393928 | `v2=3, v3=3, mod16=8, mod81=54` |
| 179480 | `m=54, b=1` | 4 | 31 | 207081 | 650902145339340 | `v2=2, v3=3, mod16=12, mod81=54` |

Full aggregate data are in the adjacent JSON artifacts.
