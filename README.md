# steelthread-platform-manifest

Demo repo for a nightly last-known-good (LKG) workflow in Harness. It stands in for a platform repo that pins every component to an image digest. All names, code, and data are fake.

## What is here

- `ts-platform.yaml`: four fake components, each pinned to a tag and digest.
- `cfn/`: a tiny CloudFormation template (SSM parameters only). The demo does not deploy it.
- `pool/pool_stub.sh`: a fake environment pool with `request`, `release`, and `list`.
- `seed/seed.sh`: a fake test-data seed.
- `tests/`: pytest suites. `test_calc.py` fails when `FORCE_CALC_FAIL=true`. `test_lineage.py` fails about 30% of runs. `test_slow_*.py` sleep 20-34 s each.
- `policies/lkg_promotion.rego`: a copy of the LKG promotion policy.
- `harness/`: the exported pipeline YAML.
- `SLOTS.md`: owner, contract, and pass/fail rule for each stage.

## The `lkg` tag

Tag `lkg` marks the last commit that passed the full nightly workflow. The pipeline moves it only when the LKG gate passes.

## Run the tests locally

```
pip install pytest
pytest tests/
FORCE_CALC_FAIL=true pytest tests/test_calc.py   # expect one failure
```
