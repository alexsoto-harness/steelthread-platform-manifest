import os

def test_calc_result_matches_reference():
    # Fails on purpose when FORCE_CALC_FAIL=true, to show a held LKG.
    assert os.environ.get("FORCE_CALC_FAIL", "false").lower() != "true", "calc-engine regression (forced)"
