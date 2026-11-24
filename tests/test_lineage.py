import os
import random

def test_lineage_graph_complete():
    # Flaky on purpose: fails about 30% of runs, to show flaky detection and quarantine.
    # FORCE_LINEAGE_FAIL=true makes it fail every time, to show quarantine absorbing a failure on demand.
    if os.environ.get("FORCE_LINEAGE_FAIL", "false").lower() == "true":
        assert False, "lineage graph missing an edge (forced)"
    assert random.random() > 0.3, "lineage graph missing an edge (flaky)"
