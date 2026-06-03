# Audit Note

This note distinguishes Altman's original implementation from local changes
made for reproducible export and verification.

## Scope And Audit Status

The computational certificate is accepted/provisionally reproducible from this
repository when `artifacts/S_46.json` is present, matches its recorded SHA256,
and the native verifier rerun reports `certificate_succeeded=True`.

The full mathematical conclusion `||2^m|| = 2m` for `m <= 56` also depends on
the inputs stated in [REDUCTION_NOTE.md](REDUCTION_NOTE.md): the public
`k <= 48` theorem and the low-defect/root-addition plus solid-correction
reduction. This repository audits the generated `S_46` certificate and
verifiers; it does not independently reprove that external framework.

The remaining final external audit step is an independent rerun from a fresh
clone with Git LFS enabled, followed by hash verification and the native
verifier command in [AUDIT_CHECKLIST.md](AUDIT_CHECKLIST.md).

## Final Certificate Summary

The final certificate artifact is:

```text
artifacts/S_46.json
```

Headline values:

```text
pair_count=2284637
max_degree=4
degree_histogram={"0":709561,"1":904288,"2":507480,"3":148632,"4":14676}
target_cases=32
survivors=0
certificate_succeeded=True
```

SHA256:

```text
1c31e69e2ed3005f396bca863fa92225409318c1aca5288acd8c876b5c815430  artifacts\S_46.json
```

Large artifact storage:

```text
artifacts/S_46.json
artifacts/checkpoints/*.json
```

are configured for Git LFS via `.gitattributes`. Hash sidecars are committed in
`artifact_hashes/`.

## Final Commands Run

```powershell
python scripts\reference_compare.py --max-threshold 16 --out-json artifacts\reference_compare.json
python -m unittest discover -s tests -v
g++ -O2 -std=c++14 native/verify_near_powers.cpp -o native/verify_near_powers
python scripts\verify_near_powers.py --self-check
.\native\verify_near_powers artifacts\S_46.json artifacts\near_power_report_native_fresh.json
```

The fresh native report matched `artifacts/near_power_report.json` on stable
certificate fields: threshold, declared pair count, parsed pair count, max
degree, degree histogram, target count, all-excluded flag, success flag, and
the full case list.

## Preserved Reference

The unmodified tarball was unpacked to:

```text
vendor/lowdefect_original/
```

The downloaded tarball remains at:

```text
lowdefect.tar.gz
```

## Changes To Altman's Existing Haskell Files

Only `vendor/lowdefect/TernaryFamilies.hs` was changed.

1. `canonub`

   Original:

   ```haskell
   canonub = nub . sort . map canon
   ```

   Local:

   ```haskell
   canonub = map head . group . sort . map canon
   ```

   Justification: after sorting, duplicate canonical families are adjacent.
   Adjacent grouping is extensionally identical to `nub` on the sorted list but
   avoids quadratic duplicate removal.

2. `supersedes` product matching

   Original generated every permutation of the second product child list.
   Local code uses direct backtracking with an exact rank prefilter before
   calling `supersedes`.

   Justification: `supersedes f g` implies equal rank, so rank mismatch is an
   exact impossibility check. Backtracking enumerates the same possible
   matchings as `permutations`, but without constructing every permutation up
   front.

3. `rm3dup1`

   Local code groups families by `SupersedesKey` before checking redundancy and
   applies the necessary condition `bcp f <= bcp g`.

   Justification: if `f` supersedes `g`, then:

   - affine constants match recursively;
   - product constants have the same 3-free part recursively;
   - child supersedes keys match as a multiset;
   - base complexity cannot increase in the superseding family.

   Therefore cross-key comparisons and higher-base-complexity comparisons
   cannot remove anything.

## New Haskell Helper Programs

These are new files and do not replace Altman's original command-line tools.

- `vendor/lowdefect/export_covering.hs`: exports `dLT !! n` as JSON.
- `vendor/lowdefect/export_range.hs`: exports checkpoint ranges and metrics.
- `vendor/lowdefect/profile_covering.hs`: profiles covering construction stages.
- `vendor/lowdefect/verify_near_powers.hs`: direct Haskell verifier used for
  smoke comparison.

## Native Verifier

`native/verify_near_powers.cpp` is a streaming exact verifier for exported JSON
coverings. It uses the same affine/product tree semantics and exact integer
arithmetic. It was added because the pure Python verifier was too slow for
`S_46`.

The native verifier:

- streams `S_46.json` one pair at a time;
- checks all 32 targets exactly;
- enumerates all subtree representations until a top-level survivor is found;
- prints exact `e`, `k_i`, complexity, and polynomial if a survivor exists.

No survivor exists in the final `S_46` run.

## Reference Comparison

`scripts/reference_compare.py --max-threshold 16` compiled the same exporter
against both:

- `vendor/lowdefect_original/`
- `vendor/lowdefect/`

and compared canonical serialized pair sets. Results through `S_16` were
identical in pair count, max degree, and canonical pair set.

The report is:

```text
artifacts/reference_compare.json
```

## Verifier Smoke Comparisons

The primary self-check is:

```text
python scripts/verify_near_powers.py --self-check
```

It runs the native verifier and the pure Python verifier on `artifacts/S_10.json`,
normalizes backend/provenance-only fields, and compares the resulting JSON
reports exactly. The result is:

```text
artifacts/verifier_self_check_S10.json
```

with `normalized_reports_equal=true`.

The native verifier agrees with prior Python smoke reports on `S_34`:

```text
artifacts/near_power_report_S34.json
artifacts/near_power_report_S34_native.json
```

Both report all 32 cases excluded for the supplied `S_34` covering, with
`certificate_succeeded=False` because `S_34` is not the target threshold.
