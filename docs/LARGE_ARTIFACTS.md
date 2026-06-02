# Large Artifact Storage

The certificate covering is intentionally large:

```text
artifacts/S_46.json
```

The checkpoint coverings are also large:

```text
artifacts/checkpoints/S_35.json
...
artifacts/checkpoints/S_46.json
```

This repository is prepared to store those JSON files with Git LFS. The normal
Git history should retain the hash sidecars in `artifact_hashes/` even if a
mirror or release workflow stores the large JSON files outside the repository.

To verify a downloaded large artifact:

```powershell
Get-FileHash -Algorithm SHA256 artifacts\S_46.json
Get-Content artifact_hashes\S_46.json.sha256
```

Do not treat the certificate as independently reproducible unless
`artifacts/S_46.json` is present and its SHA256 hash matches the recorded
sidecar.

