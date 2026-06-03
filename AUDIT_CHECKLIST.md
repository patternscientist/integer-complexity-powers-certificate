# Audit Checklist

Run commands from the repository root.

## 0. Fresh Clone Audit

Unix-like shell:

```sh
git clone https://github.com/patternscientist/integer-complexity-powers-certificate.git
cd integer-complexity-powers-certificate
git lfs install
git lfs pull
sha256sum -c artifact_hashes/S_46.json.sha256
python -m unittest discover -s tests -v
g++ -O2 -std=c++14 native/verify_near_powers.cpp -o native/verify_near_powers
./native/verify_near_powers artifacts/S_46.json artifacts/near_power_report_native_fresh.json
```

PowerShell equivalents:

```powershell
git clone https://github.com/patternscientist/integer-complexity-powers-certificate.git
Set-Location integer-complexity-powers-certificate
git lfs install
git lfs pull
Get-FileHash artifacts\S_46.json -Algorithm SHA256
Get-Content artifact_hashes\S_46.json.sha256
python -m unittest discover -s tests -v
g++ -O2 -std=c++14 native/verify_near_powers.cpp -o native/verify_near_powers.exe
.\native\verify_near_powers.exe artifacts\S_46.json artifacts\near_power_report_native_fresh.json
```

The SHA256 printed by `Get-FileHash` must match the first field in
`artifact_hashes\S_46.json.sha256`.

## 1. Check Required Artifacts

```powershell
Get-Item artifacts\S_46.json
Get-Item artifacts\near_power_report.json
Get-Item artifacts\near_power_report.md
Get-Item artifacts\reference_compare.json
```

Verify recorded SHA256 hashes:

```powershell
Get-Content artifact_hashes\*.sha256
Get-FileHash -Algorithm SHA256 artifacts\S_46.json
Get-FileHash -Algorithm SHA256 artifacts\near_power_report.json
Get-FileHash -Algorithm SHA256 artifacts\near_power_report.md
Get-FileHash -Algorithm SHA256 artifacts\reference_compare.json
```

## 2. Reference Comparison

Compare the pristine Altman source against the optimized working copy through
`S_16`:

```powershell
python scripts\reference_compare.py --max-threshold 16 --out-json artifacts\reference_compare.json
```

Expected:

```text
all_same=True
max_threshold=16
```

## 3. Generate S_46

Single-artifact export:

```powershell
python scripts\build_covering.py --threshold 46 --output artifacts\S_46.json
```

Checkpointed export with metrics:

```powershell
Set-Location vendor\lowdefect
ghc -O2 export_range.hs
.\export_range.exe 35 46 "C:\Users\poin\Documents\New project\artifacts\checkpoints\S_" |
  Set-Content -Encoding ASCII "C:\Users\poin\Documents\New project\artifacts\checkpoints\metrics_35_46.jsonl"
Set-Location ..\..
```

Expected `S_46` headline:

```text
pair_count=2284637
max_degree=4
degree_histogram={"0":709561,"1":904288,"2":507480,"3":148632,"4":14676}
```

## 4. Native Verifier

Compile the native verifier:

```powershell
g++ -O2 -std=c++14 native/verify_near_powers.cpp -o native/verify_near_powers
```

Run the native verifier directly:

```powershell
.\native\verify_near_powers artifacts\S_46.json artifacts\near_power_report_native_fresh.json
```

Compare the fresh report against the canonical report on stable certificate
fields:

```powershell
python -c "import json; a=json.load(open('artifacts/near_power_report.json')); b=json.load(open('artifacts/near_power_report_native_fresh.json')); fields=['threshold_multiple','declared_pair_count','pair_count','max_degree','degree_histogram','target_count','all_excluded','certificate_succeeded','cases']; assert all(a.get(f)==b.get(f) for f in fields); print('fresh native report matches')"
```

The wrapper command also runs the native backend by default for large coverings:

```powershell
python scripts\verify_near_powers.py --covering artifacts\S_46.json
```

Expected:

```text
backend=native_cpp_streaming
checked 32 cases
all_excluded=True
certificate_succeeded=True
```

The pure Python exact verifier is available for smaller artifacts and smoke
checks. It is not practical for `S_46` on this machine:

```powershell
python scripts\verify_near_powers.py --covering artifacts\S_10.json --required-threshold 10 --backend python
```

## 5. Verifier Self-Check

Compare the native verifier against the pure Python verifier on `S_10`:

```powershell
python scripts\verify_near_powers.py --self-check
```

Expected:

```text
self_check=True
threshold=10
pair_count=25
```

Report:

```text
artifacts/verifier_self_check_S10.json
```

## 6. Tests

```powershell
python -m unittest discover -s tests -v
```

Expected:

```text
OK
```

## 7. Reduction

Read:

```text
REDUCTION_NOTE.md
```

This separates the public `k <= 48` theorem and the low-defect reduction from
the generated `S_46` certificate.
