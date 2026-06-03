# Low-defect near-power certificate pipeline

This repository contains a reproducible certificate pipeline for the 32 checks

```text
||2^m - b|| >= 2m - 1
49 <= m <= 56
b in {1, 6, 8, 9}
```

These checks are used with the public `k <= 48` theorem and the stated
low-defect/root-addition reduction to certify the power-of-two range through
positive exponents `m <= 56`. See [REDUCTION_NOTE.md](REDUCTION_NOTE.md) for
the exact implication and scope.

## Claim Scope

This repository's computational certificate proves the 32 near-power
exclusions

```text
||2^m - b|| >= 2m - 1
49 <= m <= 56
b in {1, 6, 8, 9}
```

relative to the generated good covering `S_46` of `B_{46 delta(2)}`.

The statement

```text
||2^m|| = 2m for all m <= 56
```

follows only after combining this certificate with:

- the public Altman theorem `||2^k 3^l|| = 2k + 3l` for `k <= 48`;
- the reduction in [REDUCTION_NOTE.md](REDUCTION_NOTE.md), including the
  low-defect/root-addition and solid-correction inputs.

This repository does not independently reprove the general low-defect
machinery.

## Computational Certificate

The repository records a generated certificate:

- `artifacts/S_46.json` was generated from Altman's `dLT !! 46`.
- The verifier checked 32 near-power cases.
- No augmented low-defect representation survived.
- `certificate_succeeded=True` in `artifacts/near_power_report.json`.

The repository does not independently reprove:

- the public theorem `||2^k 3^l|| = 2k + 3l` for `k <= 48`;
- the low-defect/root-addition reduction that narrows first counterexamples in
  `49 <= m <= 56` to the listed 32 exclusions;
- Altman's low-defect covering theory.

Those are explicit dependencies of the certificate.

## Final Result

Final verifier command:

```powershell
python scripts\verify_near_powers.py --covering artifacts\S_46.json
```

Final result:

```text
backend=native_cpp_streaming
pair_count=2284637
max_degree=4
degree_histogram={"0":709561,"1":904288,"2":507480,"3":148632,"4":14676}
target_count=32
survivors=0
certificate_succeeded=True
```

Reports:

- `artifacts/near_power_report.json`
- `artifacts/near_power_report.md`

## Artifact Hashes

SHA256 sidecar files are in `artifact_hashes/`.

```text
1c31e69e2ed3005f396bca863fa92225409318c1aca5288acd8c876b5c815430  artifacts\S_46.json
e501fcc939db11b01aa58c29d9072a6596c744eb92653c646b9f6a2a7bfcdb3d  artifacts\near_power_report.json
dacdf42982f9d2896270f563585e21eed4738aaa7f31d3bad64aa76cd5039457  artifacts\near_power_report.md
b7d41ba981ccfb50dbbf735252d49806052228aa8f2f9cbd5edf2c5752b5c7e0  artifacts\reference_compare.json
```

Do not treat the theorem-level certificate as present unless the exact
`S_46.json` artifact and verifier report are present and match these hashes.

## Source And Audit

Altman's public `lowdefect` implementation was downloaded from:

```text
https://hjaltman.github.io/lowdefect.tar.gz
```

The pristine unpacked source is kept in:

```text
vendor/lowdefect_original/
```

The optimized working copy is:

```text
vendor/lowdefect/
```

See [AUDIT.md](AUDIT.md) for every change made to the working copy and the
reference-comparison evidence. The current reference comparison checks
canonical pair sets through `S_16`.

## Reproduction Checklist

Use [AUDIT_CHECKLIST.md](AUDIT_CHECKLIST.md) for exact commands.

Prerequisites:

- Python 3.11 or newer.
- GHC available on `PATH`.
- `g++` available on `PATH` for the native streaming verifier.

Core commands:

```powershell
python scripts\reference_compare.py --max-threshold 16 --out-json artifacts\reference_compare.json
python scripts\build_covering.py --threshold 46 --output artifacts\S_46.json
python scripts\verify_near_powers.py --covering artifacts\S_46.json
python scripts\verify_near_powers.py --self-check
python -m unittest discover -s tests
```

The native verifier is exact and streams the large JSON covering one pair at a
time. The pure Python exact backend remains available with `--backend python`,
but it is much slower on `S_46`.

## Large Artifact Storage

`artifacts/S_46.json` is about 551 MB. Depending on repository policy, store it
with one of:

- Git LFS;
- a release asset;
- an external archival object store.

Keep the sidecar hash file in normal Git:

```text
artifact_hashes/S_46.json.sha256
```

If `S_46.json` is not checked into Git, the README/release notes should state
where to fetch it and require verifying the recorded SHA256 before running or
trusting the final report.

## Tests

Run:

```powershell
python -m unittest discover -s tests
```

The tests cover:

- exact alpha-threshold comparisons without floating point;
- Altman's solid/chunk numbers of complexity at most 6, namely `{1, 6, 8, 9}`;
- construction of all 32 target cases;
- degree `<= 4` for `artifacts/S_46.json`.

## Checkpoint Metrics

The successful checkpoint run recorded:

```text
S_35:     42,404 pairs, max degree 3
S_36:     59,207 pairs, max degree 3
S_37:     83,201 pairs, max degree 3
S_38:    117,575 pairs, max degree 4
S_39:    167,119 pairs, max degree 4
S_40:    239,751 pairs, max degree 4
S_41:    346,205 pairs, max degree 4
S_42:    502,860 pairs, max degree 4
S_43:    733,479 pairs, max degree 4
S_44:  1,070,837 pairs, max degree 4
S_45:  1,564,504 pairs, max degree 4
S_46:  2,284,637 pairs, max degree 4
```

Detailed JSONL metrics are in `artifacts/checkpoints/metrics_35_35.jsonl` and
`artifacts/checkpoints/metrics_36_46.jsonl`.
