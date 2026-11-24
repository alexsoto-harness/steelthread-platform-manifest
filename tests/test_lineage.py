import random

def test_lineage_graph_complete():
    # Flaky on purpose: fails about 30% of runs, to show flaky detection and quarantine.
    assert random.random() > 0.3, "lineage graph missing an edge (flaky)"
